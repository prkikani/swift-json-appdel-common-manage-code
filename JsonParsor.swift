
import Foundation

class JsonParsor
{
    var jsonURL : String! = ""
    var parms : String!
    
    func forData(completion: @escaping ([String : Any]) -> ())
    {
        if jsonURL != nil && parms != nil
        {
            if let url = URL(string: jsonURL)
            {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.httpBody = parms.data(using: String.Encoding.utf8)
                
                let task = URLSession.shared.dataTask(with: request) {
                    data, response, error in
                    
                    //                let httpResponse = response as! HTTPURLResponse
                    //                let statusCode = httpResponse.statusCode
                    
                    if (data != nil) && error == nil
                    {
                        do
                        {
                            let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : Any]
                            completion(json)
                        }catch {
                            DLog("Error with Json: \(error)")
                        }
                    }
                    else
                    {
                        DLog("error=\(error!.localizedDescription)")
                    }
                }
                task.resume()
            }
            else{
                DLog("please Enter proper url and json perametors")
            }
        }
        else{
            DLog("please Enter proper url and json perametors")
        }
    }
}
