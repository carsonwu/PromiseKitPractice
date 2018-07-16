/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import Foundation
import PromiseKit

fileprivate let appID = "9f1c96cbc2e7e39a1bf48077d7e6cdc5"

class WeatherHelper {
  
  struct Weather {
    let tempInK: Double
    let iconName: String
    let text: String
    let name: String
    
    init?(jsonDictionary: [String: Any]) {
      
      guard let main =  jsonDictionary["main"] as? [String: Any],
        let tempInK = main["temp"] as? Double,
        let weather = (jsonDictionary["weather"] as? [[String: Any]])?.first,
        let iconName = weather["icon"] as? String,
        let text = weather["description"] as? String,
        let name = jsonDictionary["name"] as? String else {
        print("Error: invalid jsonDictionary! Verify your appID is correct")
        return nil
      }
      self.tempInK = tempInK
      self.iconName = iconName
      self.text = text      
      self.name = name
    }
  }
  
    /*
  func getWeatherTheOldFashionedWay(latitude: Double, longitude: Double, completion: @escaping (Weather?, Error?) -> ()) {
    
    assert(appID == "9f1c96cbc2e7e39a1bf48077d7e6cdc5", "You need to set your API key!")
    
    let urlString = "http://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(appID)"
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)
    
    let session = URLSession.shared
    let dataTask = session.dataTask(with: request) { data, response, error in
      
      guard let data = data,
        let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
        let result = Weather(jsonDictionary: json) else {
          completion(nil, error)
          return
      }
      
      completion(result, nil)
    }
    dataTask.resume()
  }
    */
    
    func getWeatherFrom(latitude: Double, longitude: Double) -> Promise<Weather> {
        return Promise { seal in
            let urlString = "http://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(appID)"
            let url = URL(string: urlString)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            session.dataTask(.promise, with: request).compactMap({ (data, response)/* -> [String : Any]?*/ in
                // Return type [String : Any]? can be inferred from the single statement below
                try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            }).compactMap{
                //Return type is inferred from the below statement & argument is inferred from Shorthand Argument Names $0. Thus all the arguments and return type can be ommitted
                Weather(jsonDictionary: $0)
            }.done({ (weather) in
                seal.fulfill(weather)
            }).catch({ (error) in
                seal.reject(error)
            })
            /*
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any],
                    let result = Weather(jsonDictionary: json) {
                        seal.fulfill(result)
                }else if let err = error{
                    seal.reject(err)
                }else{
                    let error = NSError(domain: "PromiseKitTutorial", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                    seal.reject(error)
                }
            })
            dataTask.resume()
            */
        }
    }
    
    func getWeatherIcon(with iconName: String) -> Promise<UIImage> {
        return Promise { seal in
            
            //First, try to load image from device
            getFile(named: iconName, completion: { image in
                if let image = image {
                    print("Loaded image from device")
                    seal.fulfill(image)
                }else{
                    
                    //Second, download the image from web if the image does not exist in device
                    self.getWeatherIconFromWeb(iconName: iconName).done({ (image) in
                        print("Loaded image from web")
                        seal.fulfill(image)
                    }).catch({ (error) in
                        seal.reject(error)
                    })
                }
            })
        }
    }
    
    func getWeatherIconFromWeb(iconName: String) -> Promise<UIImage> {
        return Promise { seal in
            let urlString = "http://openweathermap.org/img/w/\(iconName).png"
            let url = URL(string: urlString)!
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(.promise, with: request).compactMap(on: DispatchQueue.global(qos: .background), flags: [], {
                UIImage(data: $0.data)
            }).done{
                seal.fulfill($0)
                }.catch({ (error) in
                    seal.reject(error)
                })
        }
    }
  
  private func saveFile(named: String, data: Data, completion: @escaping (Error?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(named+".png") {
        do {
          try data.write(to: path)
          print("Saved image to: " + path.absoluteString)
          completion(nil)
        } catch {
          completion(error)
        }
      }
    }
  }
  
  private func getFile(named: String, completion: @escaping (UIImage?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      var image: UIImage?
      if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(named+".png") {
        if let data = try? Data(contentsOf: path) {
          image = UIImage(data: data)
        }
      }
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
  
}
