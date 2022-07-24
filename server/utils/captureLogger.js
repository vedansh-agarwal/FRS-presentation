const fs = require("fs");
const path = require("path");
const log_filesFolder = path.join(__dirname, "..", "..", "Attendance_Files");

function pad(str, len) {
    return (str+Array(len).join(" ")).substring(0, len);
}

function clog(name, roll_no, classname) {
    const att_date = new Date().toLocaleString().substring(0, 10).replace(/\//g, "-")
    const user_capture_file = path.join(log_filesFolder, classname+"_Attendance_"+att_date+".txt");
    fs.exists(user_capture_file, function (exists) {
        if(!exists)
        {
            fs.writeFile(user_capture_file, pad("Name", 20)+pad("Roll No.", 15)+pad("Time Joined", 15)+"\n\n", function (err) {
                if (err) throw err;
            });
        }
        fs.appendFile(user_capture_file, pad(name, 20)+pad(roll_no, 15)+pad(new Date().toLocaleTimeString(),15)+"\n", function (err) {
            if (err) throw err;
        });
    });
}

module.exports = clog;