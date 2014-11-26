// Put your javascript here and it will automatically be loaded on each page.

// Change project title in header
function setupProjectTitle() {
    var project_title = $('#header h1').html();
    var pathname = window.location.pathname;

    if  (pathname.match('/projects/') || pathname.match('/issues/')) {
        $('#header h1').html('Taskman project: ' + project_title);
    }
}

function insertRightImageContainer() {
    var redmine_header = $('#header');
    redmine_header.append('<div id="right-image-container"></div>');
}  

// Load custom JavaScript
jQuery(document).ready(function() {
    setupProjectTitle();
    insertRightImageContainer();
});
