$(function () {
    // Workaround (hopefully temporary) for http://www.redmine.org/issues/14571
    fixDate("input#issue_start_date");
    fixDate("input#issue_due_date");

    function fixDate(fieldId) {
        var field = $(fieldId);
        if (field.length == 1) {
            field.val(field.val().replace(/[A-z]{3} ([A-z]{3}) ([0-9]{2}) [0-9:]{8} \+[0-9]{4} ([0-9]{4})/, "$3-$1-$2")
                .replace("Jan", "01")
                .replace("Feb", "02")
                .replace("Mar", "03")
                .replace("Apr", "04")
                .replace("May", "05")
                .replace("Jun", "06")
                .replace("Jul", "07")
                .replace("Aug", "08")
                .replace("Sep", "09")
                .replace("Oct", "10")
                .replace("Nov", "11")
                .replace("Dec", "12")
                );
        }
    }
});