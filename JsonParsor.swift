//
//  JsonParsor.swift
//  Test
//
//  Created by admin on 29/07/19.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import UIKit
enum HttpMethod : String {
    case  GET
    case  POST
    case  DELETE
    case  PUT
}

/*  if you want call 
 var params : [String:Any] = [:]
 params["id"] = "136"
 
 let base64 = convertImageTobase64(format: .png, image: UIImage(named: "sample"))
 params["image"] = base64
 
 let token = "AuthorizxationToken"
 
 JsonParsor().jsonParse(WithUrl: "URL OF API", param: params, token: token) { (response) in
 print(response)
 }
 */
class JsonParsor {
    func jsonParse(WithUrl:String,param:[String:Any]?,token:String?,completion: @escaping ([String : Any]) -> ()) {
        if let url = URL(string: WithUrl)
        {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            if let params = param {
                let  jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                request.httpBody = jsonData//?.base64EncodedData()
                //paramString.data(using: String.Encoding.utf8)
            }
            if let headerToken = token {
                request.addValue("Bearer \(headerToken)", forHTTPHeaderField: "Authorization")
            }
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"

            let configuration = URLSessionConfiguration.default
            
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 30
            
            let session = URLSession(configuration: configuration)

            let task = session.dataTask(with: request) {
                data, response, error in
                if (data != nil) && error == nil
                {
                    do
                    {
                        let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : Any]
                        completion(json)
                    }catch {
                        print("Error with Json: \(error)")
                    }
                }
                else
                {
                    print("error=\(error!.localizedDescription)")
                }
            }
            task.resume()
        }
        else{
            print("please Enter proper url and json perametors")
        }
    }
    
    func uploadImage(paramName: String, fileName: String, image: UIImage) {
        let url = URL(string: "http://api-host-name/v1/api/uploadfile/single")
        
        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString
        
        let session = URLSession.shared
        
        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        
        // Set Content-Type Header to multipart/form-data, this is equivalent to submitting form data with file upload in a web browser
        // And the boundary is also set here
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(image.pngData()!)
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Send a POST request to the URL, with the data we created earlier
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            if error == nil {
                let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                if let json = jsonData as? [String: Any] {
                    print(json)
                }
            }
        }).resume()
    }
}


public enum ImageFormat {
    case png
    case jpeg(CGFloat)
}

func convertImageTobase64(format: ImageFormat, image:UIImage) -> String? {
    var imageData: Data?
    switch format {
    case .png: imageData = image.pngData()
    case .jpeg(let compression): imageData = image.jpegData(compressionQuality: compression)
    }
    return imageData?.base64EncodedString()
}
