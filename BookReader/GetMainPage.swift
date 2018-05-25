//
//  GetMainPage.swift
//  BookReader
//
//  Created by 李刚 on 2018/5/25.
//  Copyright © 2018年 李刚. All rights reserved.
//

import Foundation
import Alamofire
import SwiftSoup
protocol UpdateMainPageDelegate:class {
    func updateMainPage(index: Int, content: BookCellContent)
}

class GetMainPage {
    static var currentRequests = [DataRequest]()
    let mHeader:HTTPHeaders = ["Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1",
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"]
    var updateMainPageDelegate: UpdateMainPageDelegate?
    func getMainPage(path:String,index: Int) {
        
        
        let dq = Alamofire.request(path, method: HTTPMethod.get, parameters: nil, encoding: URLEncoding.default, headers: mHeader)
        GetMainPage.currentRequests.append(dq)
        dq.responseData(queue: DispatchQueue.global()) {[weak self] resp in
            var info = [String:Any]()
            var host = ""
            var _name = "请求失败"
            var _author = ""
            var _time = ""
            var _chapter = ""
            var _url = ""
            var _img = ""
            var _all = ""
            var latestedTen = [(String,String)]()
            
            if resp.result.isSuccess,let data = resp.result.value {
                var parseString = ""
                host = (resp.request?.url?.host)!
                if host == "m.zwdu.com"{
                    parseString = String(data: data, encoding: String.Encoding.windowsCP1254)!
                }else{
                    parseString = String(data: data, encoding: .utf8)!
                }
                do {
                    let doc: Document = try SwiftSoup.parse(parseString)
                    let book_txt = try doc.select("div.block_txt2")
                    _name = (try book_txt.select("h2").first()?.text()) ?? ""
                    _img = (try doc.select("div.block_img2").select("img").first()?.attr("src")) ?? ""
                    _author = (try book_txt.select("p:eq(3)").first()?.text()) ?? ""
                    _time = (try book_txt.select("p:eq(6)").first()?.text()) ?? ""
                    _chapter = (try book_txt.select("a").last()?.text()) ?? ""
                    _url = (try book_txt.select("a").last()?.attr("href")) ?? ""
                    
                } catch {
                    print("error")
                }
            }
            DispatchQueue.main.async {
                
            self?.updateMainPageDelegate?.updateMainPage(index: index, content: BookCellContent(name: _name, author: _author, time: _time.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), chapter: _chapter, url: _url, img: _img, all: _all.replacingOccurrences(of: " ", with: ""), latestedTen: latestedTen, host: host))
        }
        }
    }
    static func cancel(){
        for i in currentRequests{
            i.cancel()
        }
        currentRequests.removeAll()
    }
    static func cancel(which:Int){
        currentRequests[which].cancel()
        currentRequests.remove(at: which)
    }
}
