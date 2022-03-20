function say(r: NginxHTTPRequest) {
  r.headersOut['Content-Type'] = 'text/plain'
  r.return(200, 'Hello!')
}

export default {
  say,
}
