//
//  WeatherViewController.swift
//  MyWeatherExample
//
//  Created by bro on 2022/05/09.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation
import Kingfisher

class WeatherViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var tempTextView: UITextView!
    @IBOutlet weak var humidityTextView: UITextView!
    @IBOutlet weak var windSpeedTextView: UITextView!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var messageTextView: UITextView!
    
    
    private var locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D() {
        didSet {
            fetchWeather(location: currentLocation)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationMangerConfig()
        viewConfig()
    }
    
    func locationMangerConfig() {
        locationManager.delegate = self
    }
    
    func viewConfig() {
        textViewConfig()
        weatherImageViewCofing()
        dateLabelConfig()
    }
    
    func textViewConfig() {
        let textviews = [
            tempTextView,
            humidityTextView,
            windSpeedTextView,
            messageTextView
        ]
        
        for textview in textviews {
            textview?.layer.masksToBounds = true
            textview?.layer.cornerRadius = 10
            textview?.textContainerInset.left = 10
            textview?.textContainerInset.right = 10
        }
    }
    
    func weatherImageViewCofing() {
        weatherImageView.clipsToBounds = true
        weatherImageView.layer.cornerRadius = 10
    }
    
    func dateLabelConfig() {
        let currentDate = Date()
        let formatter = DateFormatter()

        formatter.dateFormat = "MM월 dd일 hh시 mm분"
        
        dateLabel.text = formatter.string(from: currentDate)
    }
    
    func fetchWeather(location: CLLocationCoordinate2D) {
        setLocationLabel(location: location)
        AF.request(Constants.weatherUrl(lat: location.latitude, lon: location.longitude), method: .get)
            .validate().responseJSON { response in
            switch response.result  {
            case .success(let value) :
                let json = JSON(value)
                
                print(json)
                
                let temperature = json["main"]["temp"].doubleValue
                let humidity = json["main"]["humidity"].stringValue
                let windSpeed = json["wind"]["speed"].stringValue
                let icon = json["weather"][0]["icon"].stringValue
                let statusImageURL = "https://openweathermap.org/img/wn/\(icon)@2x.png"
                
                let weather = WeatherData(temperature: "\(temperature)",
                                      humidity: humidity,
                                      windSpeed: windSpeed,
                                      imageURL: statusImageURL)
                
                self.updateWeatherUI(weatherData: weather)
                
            case .failure(let error) :
                print("error")
            }
        }
    }
    
    func updateWeatherUI(weatherData: WeatherData) {
        tempTextView.text = "지금은 \(weatherData.temperature)°C 에요"
        humidityTextView.text = "\(weatherData.humidity)%만큼 습해요"
        windSpeedTextView.text = "\(weatherData.windSpeed)m/s의 바람이 불어요"
        weatherImageView.kf.setImage(with: URL(string: weatherData.imageURL))
    }
    
    func setLocationLabel(location: CLLocationCoordinate2D) {
        
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr")
        
        
        geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude), preferredLocale: locale) { placemark, error in
            if let err = error {
                print(err)
            }
            else {
                let place = placemark?.first
                let administrativeArea = place?.administrativeArea ?? ""
                let subLocality = place?.subLocality ?? ""
                self.locationLabel.text = "\(administrativeArea), \(subLocality)"
            }
        }
        
    }
    
    @IBAction func refreshButtonClicked(_ sender: UIButton) {
        checkUserLocationServicesAuthorization()
    }
}


// MARK: - LocationManager 딜리게이트 등록
extension WeatherViewController: CLLocationManagerDelegate {
    
    //9. ios 버전에 따른 분기 처리와 ios 위치 서비스 여부 확인
    func checkUserLocationServicesAuthorization() {
        let authorizationStatus: CLAuthorizationStatus
        
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus // ios 14이상에만 사용 가능.
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus() // ios 14미만에서 사용
        }
        
        
        //iOS 위치 서비스 확인
        if CLLocationManager.locationServicesEnabled() {
            //위치 서비스를 사용할 수 있는 상태여야지만
            //권한 상태를 확인 할 수 있다.
            checkCurrentLocationAuthorization(authorizationStatus)
        } else {
            showAlert(title: "기기 위치 설정 미활성화", message: "현재 위치의 날씨정보를 위해 권한이 필요합니다.", okTitle: "확인", okAction: openSettingURL)
        }
    }
    
    //8. 사용자의 권한 상태 확인.(UDF : 사용자 정의 함수)
    // 사용자가 위치를 허용했는지 안했는지 거부한건지 이런 권한을 확인!
    // 단 ios의 위치서비스가 켜져있는지, 가능한지 확인이 먼저!
    func checkCurrentLocationAuthorization(_ authorizationStatus: CLAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest//정확한 위치를 얻을 때 반경을 몇으로 할지 설정하는 것. Best로 하면 자동으로 해준다.
            locationManager.requestWhenInUseAuthorization() //앱을 사용하는 동안에 대한 위치 권한 요청
            locationManager.startUpdatingLocation() //권한 획득후 위치를 업데이트하라는 함수
        case .restricted, .denied:
            showAlert(title: "기기 위치 설정 미활성화", message: "현재 위치의 날씨정보를 위해 권한이 필요합니다.", okTitle: "확인", okAction: openSettingURL)
        case .authorizedWhenInUse:
            locationManager.startUpdatingLocation() //앱을 사용하는 동안에 대한 위치 권한 요청 => didUpdateLocations 함수 실행!
        case .authorizedAlways:
            print("Always")
        @unknown default:
            print("DEFAULT")
        }
        
        if #available(iOS 14.0, *) {
            //정확도 체크 : 정확도가 감소가 되어 있는 경우. 1시간에 4번밖에 호출을 못함, 미리 알림이 동작을 안할 수 있다. 대신 배터리는 오래 쓸 수 있다. 워치8 부터 위치 페어링기능이 동작하지 않는다
            let accurancyState = locationManager.accuracyAuthorization
            
            switch accurancyState {
            case .fullAccuracy:
                print("FULL")
            case .reducedAccuracy:
                print("REDUCE")
            @unknown default :
                print("DEFAULT")
            }
        }
    }
    
    
    //4. 사용자가 위치 허용을 한 경우 실행
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(#function)
        print(locations)
        
        if let coordinate = locations.last?.coordinate {
           
            currentLocation = coordinate
            //10. 매우 중요!! 업데이트를 멈춰주어야한다.(자동으로 계속 되고 있다)
            //비슷한 반경에서는 업데이트를 안하도록 해주는 그런 코드는 직접 구현해주어야 한다.
            locationManager.stopUpdatingLocation()
            
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    //5. 위치권한을 허용을 해두었지만, 어떠한 이유(비행기 모드 등)으로 위치정보를 획득하지 못하는 경우
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
    }
    
    //6. ios14 미만 : 앱이 위치 관리자를 생성하고, 승인 상태가 변경이 될 때 대리자에게 승인 상태를 알려줌.
    // 권한이 변경될 때 마다 감지해서 실행. -> 이 화면에 접근하고 있을때만이지 않을까?
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserLocationServicesAuthorization()
    }
    
    //7. ios14 이상 : 앱이 위치 관리자를 생성하고, 승인 상태가 변경이 될 때 대리자에게 승인 상태를 알려줌.
    // 권한이 변경될 때 마다 감지해서 실행.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkUserLocationServicesAuthorization()
    }
    
}
