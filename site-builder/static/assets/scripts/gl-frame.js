(function ()
{
    var cv = document.getElementsByClassName("gl-contentview")[0];
    var nb = document.getElementsByClassName("gl-navbar")[0];
    var resizeHandler = function ()
    {
        cv.style.height = (window.innerHeight - nb.offsetHeight).toString() + "px";
    };
    resizeHandler();
    window.addEventListener("resize", resizeHandler);
    var ai = document.getElementsByClassName("gl-accessibility-helper-iframe")[0];
    ai.contentWindow.addEventListener("resize", resizeHandler);
})();
