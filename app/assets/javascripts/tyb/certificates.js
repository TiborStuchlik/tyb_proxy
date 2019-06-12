
function changeGenerated(sender) {
    ch = $('#generatedCheckbox')
    cg = $('#certificateGenerated')
    cm = $('#certificateManual')
    if (ch.is(':checked')) {
        cm.css('display', 'none')
        cg.css('display', 'inline')
    } else {
        cg.css('display', 'none')
        cm.css('display', 'inline')
    }
}