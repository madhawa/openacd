function createRequestObject() {
    var xmlhttpindex = null;
    if (window.XMLHttpRequest) {
	xmlhttpindex = new XMLHttpRequest();
    }else if (window.ActiveXObject) {// ??? IE:
	xmlhttpindex = new ActiveXObject("Microsoft.XMLHTTP");
    }else{
	xmlhttpindex = null;
    }
    return xmlhttpindex;
}

var answer='';

function serverGetRequest(url) {
    var request = createRequestObject();
    if(!request) return false;
    request.open("GET",url,false);
    request.send(null);
    answer=request.responseText;
    return answer;
}

function serverGetRequest2(url,func) {
    request = createRequestObject();
    if(!request) return false;
    request.onreadystatechange = func;
    request.open("GET", url, true);
    request.send(null);
    return true;
}
