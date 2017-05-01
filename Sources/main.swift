import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectCURL

/// home page
/// click the "Direct Post" then you can see the post result
/// or click the hyper link then you can see the curl result
func rootGetHandler(data: [String:Any]) throws -> RequestHandler {
	return {
		request, response in
		let homepage = "<html><title>Post Example</title><body><h1>Post Example</h1><form method=post>" +
    "<input type=text name=number value=100><br>" +
    "<input name=string type=text value='my string value'><br>" +
    "<input type=submit value='Direct Post'>" +
    "</form><hr><a href='http://localhost:8080/users/string=anonymous+number=200'>http://localhost:8080/users/anonymous</a></body></html>"

		response.setHeader(.contentType, value: "text/html")
      .appendBody(string: homepage).completed()
	}
}

/// the actual post responser
func rootPostHandler(data: [String:Any]) throws -> RequestHandler {
  return {
    request, response in
    let number = request.param(name: "number") ?? "123"
    let string = request.param(name: "string") ?? "hello"
    let page = "<html><title>Post Example</title><body>" +
      "<h1>Number: \(number)</h1><h1>String: \(string)</h1></body></html>"
    response.setHeader(.contentType, value: "text/html")
      .appendBody(string: page).completed()
  }
}

/// a bridge from url to post by curl command
func rootUsersHandler(data: [String:Any]) throws -> RequestHandler {
  return {
    request, response in

    guard let keywords = request.urlVariables["keywords"] else {
      response.completed()
      return
    }//end guard

    response.setHeader(.contentType, value: "text/html")

    let fields = CURL.POSTFields()

    // "+"
    for exp in keywords.utf8.split(separator: 32) {
      let e = exp.split(separator: 61)
      guard e.count > 1, let key = String(e[0]), let value = String(e[1]) else { continue }
      _ = fields.append(key: key, value: value)
    }

    let curl = CURL(url: "http://localhost:8080/")
    _ = curl.formAddPost(fields: fields)

    let r = curl.performFullySync()
		curl.close()
    guard r.resultCode == 0 else {
      response.appendBody(string: "<H1>FAULT</H1>").completed()
      return
    }//end guard

    var bytes = r.bodyBytes
    bytes.append(0)
    let ret = String(cString: bytes)
    response.appendBody(string: "<H1>CURL RESPONSE</H1><textarea cols=40 rows=10>\(ret)</textarea>").completed()
  }
}

let confData = [
	"servers": [
		[
			"name":"localhost",
			"port":8080,
			"routes":[
				["method":"get", "uri":"/", "handler":rootGetHandler],
				["method":"post", "uri":"/", "handler":rootPostHandler],
				["method":"get", "uri":"/users/{keywords}", "handler":rootUsersHandler],
			]
		]
  ]
]

do {
	// Launch the servers based on the configuration data.
	try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}
