const fs = require("fs");
const { v4: uuidv4 } = require('uuid');
const path = require("path");
const { spawnSync } = require("child_process");

const db = require("../db/dbconnect");
const user_imagesFolder = path.join(__dirname, "..", "..", "user_images");
const uploadsFolder = path.join(user_imagesFolder, "uploads");
const tempFolder = path.join(user_imagesFolder, "temp");
const deletesFolder = path.join(user_imagesFolder, "deletes");
const capturesFolder = path.join(user_imagesFolder, "captures");

const clog = require("../utils/captureLogger");

const fe_file = path.join(__dirname, "..", "face_encodings", "face_encodings.json");
const pyscripts = path.join(__dirname, "..", "pyscripts");
const recface = path.join(pyscripts, "recface.py");

const recognizeUser = async (req, res) => {
    var { base64img, in_out_status } = req.body;

    if(!base64img) {
        return res.status(206).json({ msg: "no image recieved" });
    }

    if(in_out_status != "IN" && in_out_status != "OUT") {
        return res.status(400).send({msg:"Invalid in_out_status"});
    }

    var extension = "." + base64img.substring(11, base64img.indexOf(";"));
    if(extension !== ".png" && extension !== ".jpeg") {
        return res.status(415).json({ msg: "unsupported filetype" });
    }
    var img = uuidv4()+extension;

    const imgpath = path.join(capturesFolder, img);

    const base64str = base64img.substring(base64img.indexOf(",")+1);
    fs.writeFileSync(imgpath, base64str, "base64");

    const process = spawnSync("python3", [recface, imgpath, fe_file, "user"]);
    const finalResult = JSON.parse(String(process.stdout).replace(/'/g, '"'));

    if(finalResult.msg === "no face found" || finalResult.msg === "multiple faces found") {
        // fs.unlinkSync(imgpath);
        return res.status(211).json({msg: finalResult.msg});
    }
    else if(finalResult.msg === "existing user") {
        img = finalResult.user_id + extension;
        db.promise().query("CALL record_user_capture(?,?,?)", [img, finalResult.user_id, in_out_status])
        .then((result) => {
            fs.renameSync(imgpath, path.join(capturesFolder, result[0][0][0]["@img_name"]))
            var user_name = result[0][0][0]["@user_name"];
            clog(result[0][0][0]["@user_name"], result[0][0][0]["@city"], result[0][0][0]["@department"]);
            if(in_out_status == "IN") {
                return res.status(211).json({msg: `Hello ${user_name}!`, user_id: finalResult.user_id});
            }
            else {
                return res.status(211).json({msg: `Bye ${user_name}`, user_id: finalResult.user_id});
            }
        })
        .catch((err) => {
            console.log(err);
            res.status(500).json({ msg: err.sqlMessage });
        });
    }
    else {
        db.promise().query("CALL record_user_capture(?,?,?)", [img, "unrecognized", in_out_status])
        .catch((err) => {
            console.log(err);
            res.status(500).json({ msg: err.sqlMessage });
        });
        return res.status(211).json({msg: "User Not Recognized"});
    }
}

module.exports = {
    recognizeUser
};