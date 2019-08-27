func uploadFile(_ params:[String : Any] = [:]) {
        var body = Data()
        let BoundaryConstant = "----------V2ymHFg03ehbqgZCaKO6jy"
        for (key, value) in params {
            body.append("--\(BoundaryConstant)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
       
        let FileParamConstant = "img_name" // file Paramter which are stored in file 
        
        // create request
        var request = URLRequest(url: URL(string: "URL")!)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpShouldHandleCookies = false
        request.timeoutInterval = 30
        request.httpMethod = "POST"
        
        // set Content-Type in HTTP header
        let contentType = "multipart/form-data; boundary=\(BoundaryConstant)"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(ACCESS_TOKEN, forHTTPHeaderField: "Authorization")
                
//        let stringPath = Bundle.main.path(forResource: "input", ofType: "txt")
        let urlPath = Bundle.main.url(forResource: "input", withExtension: "txt")
        let mimtype = MimeType(ext: urlPath!.pathExtension)
        let filename = urlPath!.lastPathComponent
        let data = try? Data(contentsOf: urlPath!)

        
        // add File data
        if data != nil {
            if let data = "--\(BoundaryConstant)\r\n".data(using: .utf8) {
                body.append(data)
            }
            if let data = "Content-Disposition: form-data; name=\"\(FileParamConstant)\"; filename=\"\(filename)\"\r\n".data(using: .utf8) {
                body.append(data)
            }
            if let data = "Content-Type: \(mimtype)\r\n\r\n".data(using: .utf8) {
                body.append(data)
            }
            if let imageData = data {
                body.append(imageData)
            }
            if let data = "\r\n".data(using: .utf8) {
                body.append(data)
            }
        }
        
        if let data = "--\(BoundaryConstant)--\r\n".data(using: .utf8) {
            body.append(data)
        }
        
        // setting the body of the post to the reqeust
        request.httpBody = body
        
        // set the content-length
        let postLength = "\(body.count)"
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        
        URLSession.shared.dataTask(with: request) { (data, response
            , error) in
            guard let data = data else { return }
            do {
                let json  = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                print(json)
            } catch let err {
                print("Err", err)
                
            }
            }.resume()
    }
    
