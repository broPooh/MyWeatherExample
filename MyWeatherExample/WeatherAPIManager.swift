//
//  WeatherAPIManager.swift
//  MyWeatherExample
//
//  Created by bro on 2022/05/10.
//

import Foundation
import Alamofire
import SwiftyJSON

class WeatherAPIManager {
    static let shared = WeatherAPIManager()
    
    func fetchWeather(lat: Double, lon: Double, result: @escaping (Int, WeatherData) -> ()) {
        
        AF.request(Constants.EndPoint.weatherUrl(lat: lat, lon: lon), method: .get)
            .validate().responseJSON { response in
            switch response.result  {
            case .success(let value) :
                let json = JSON(value)
                               
                let temperature = json["main"]["temp"].doubleValue
                let humidity = json["main"]["humidity"].stringValue
                let windSpeed = json["wind"]["speed"].stringValue
                let icon = json["weather"][0]["icon"].stringValue
                let statusImageURL = "https://openweathermap.org/img/wn/\(icon)@2x.png"
                
                let weather = WeatherData(temperature: "\(temperature)",
                                      humidity: humidity,
                                      windSpeed: windSpeed,
                                      imageURL: statusImageURL)
                
                let code = response.response?.statusCode ?? 500
                result(code, weather)
                                
            case .failure(let error) :
                print(error)
            }
        }
    }
}
