jf = require 'jsonfile'
request = require "request"
j = request.jar()
request = request.defaults jar: j # enable cookie jar
_ = require "lodash"
window = {}
jsdom = require("jsdom")
$ = null
jsdom.env "<html><body></body></html>", (err, win)->
  $ = require('jquery')(win)
  getXSRF login

QUSTION_FILE = "questions.json"
questionID = 82312
questions = []

opt = 
  url: ""
  headers:
    "Cache-Control": "no-cache"
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2434.0 Safari/537.36"
    "Host": "www.zhihu.com"
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    "Accept-Encoding": "gzip, deflate, sdch"
    "Accept-Language": "zh-CN,zh;q=0.8,en;q=0.6"
    "HTTPS":1
    "Pragma": "no-cache"
    "Proxy-Connection": "keep-alive"
  gzip: yes
  #proxy: "http://web-proxy.oa.com:8080"

LOGIN_URL = "http://www.zhihu.com/login"
ZHIHU_URL = "http://www.zhihu.com"

_xsrf = null
getXSRF = (cb)->  
  # GET _xsrf value
  opt.url = ZHIHU_URL
  opt.method = "GET"
  request opt, (err, res, body)->
    resetXSRF body
    cb()

login = ->
  opt.url = LOGIN_URL
  opt.method = "POST"
  opt.form = 
    _xsrf: _xsrf
    email: "livoras@163.com"
    password: "mmdev123"
    rememberme: "y"
  request opt, (err, res, body)->
    loopQuestions()

loopQuestions = ->
  questionID++
  if questionID > 40000000
    return
  opt.url = "http://www.zhihu.com/question/#{questionID}"
  opt.method = "GET"
  request opt, (err, res, body)->
    console.log "Doing #{questionID} ===== Count : #{questions.length}"
    if res.statusCode is 200
      console.log "Good: #{questionID}"
      questions.push questionID
      jf.writeFile QUSTION_FILE, questions
    else
      console.log "Bad(#{res.statusCode}): #{questionID}"
    loopQuestions()

recommend = ->    
    navigateTo 'http://www.zhihu.com/explore', ->
      navigateTo 'http://www.zhihu.com/explore/recommendations', initCrawler

navigateTo = (url, cb)->
  opt.url = url
  opt.method = "GET"
  request opt, (err, res, body)->
    cb err, res, body

initCrawler = ->
  _xsrf = j.getCookies(ZHIHU_URL).join ";"
           .match(/_xsrf=\w+/)[0]
           .replace('_xsrf=', '')
  limit = 1
  offset = 0
  _.extend opt, 
    method: "POST"
    url: 'http://www.zhihu.com/node/ExploreRecommendListV2'
    form:
      method: 'next'
      params: JSON.stringify {limit, offset}
      _xsrf: _xsrf
  request opt, (err, res, body)->
     JSON.parse body

resetXSRF = (body)->
  _xsrf = $(body).find("input[name=_xsrf]").val()
