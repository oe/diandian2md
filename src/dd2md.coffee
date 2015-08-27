path = require 'path'
fs = require 'fs'
http = require 'http'
iconv = require 'iconv-lite'
{parseString} = require 'xml2js'
savePath = ''

# 给数字添加前置0
prefix0: (n, len = 2)->
  n = "#{n}"
  if n.length < len
    n = Array(len - n.length + 1).join('0') + n
  n
###*
 * 将时间格式化时间字符串
 *
 * @param  {Number} timeStamp 时间戳或者时间对象
 * @param  {String} format    时间的目标格式, 默认格式为 yyyy-MM-dd hh:mm:ss.ms
 * @return {Strng}           格式化后的时间
###
formatTime = (timeStamp, format='yyyy-MM-dd hh:mm:ss.ms')->
  t = new Date timeStamp
  return '' if not format or isNaN t.valueOf()
  # 月
  M = t.getMonth() + 1
  # 日
  D = do t.getDate
  # 时
  H = do t.getHours
  # 分
  m = do t.getMinutes
  # 秒
  s = do t.getSeconds
  # 微妙
  ms = do t.getMilliseconds
  tt =
    yy: utils.prefix0 t.getYear() % 100
    yyyy: t.getFullYear()
    MM: utils.prefix0 M
    M: M
    dd: utils.prefix0 D
    d: D
    hh: utils.prefix0 H
    h: H
    mm: utils.prefix0 m
    m: m
    ss: utils.prefix0 s
    s: s
    ms: ms

  format.replace /[a-z]+/ig, ($0)->
    tt[ $0 ] ? $0
# 获取文件内容
getContentFrom = (url, done)->
  # 在线内容
  if /^http:\/\//.test url
    xml = ''
    req = http.get url, (res)->
      res.setEncoding 'binary'
      res.on 'data', (data)->
        xml += data;
      .on 'end', ->
        buf = new Buffer xml, 'binary'
        #将GBK编码的字符转换成utf8的
        str = iconv.decode buf, 'utf-8'
        done str
      .on 'close', ->
        console.log 'Close received!'
      return

    req.on 'error', (error)->
      console.error "can not access <#{url}> because of #{error.message}"
  else
    fs.readFile url, (error, str)->
      if error
        console.error "can not read file <#{url}> because of #{error.message}"
      else
        done str
      return

# 解析rss内容
parseRss = (content)->
  parseString content, {explicitArray: false}, (error, xml)->
    if error
      console.error "failed to parse xml content because of #{error.message}"
    else
      xml = xml.DiandianBlogBackup
      getImageUrl.imgs = xml.Images.Image

      getBlogMeta xml.BlogInfo

      parsePosts xml.Posts.Post
      fs.writeFile('love.log', JSON.stringify(xml, null, 2), 'utf-8');

# 获取标签信息
getBlogTags = (tags)->
  return '' unless tags
  tags = tags.tag
  tags = [tags] unless Array.isArray tags
  '\n - ' + tags.join '\n - '

# 获取博客自定义的uri
getBlogUri = (uri)->
  return '' unless uri
  /([^\/]+)$/.exec(uri)[1]

# 获取博客基础信息, 输出至yaml
getBlogMeta = (blogInfo)->
  

# 根据图片id查找图片
getImageUrl = (imgId)->
  imgs = getImageUrl.imgs
  for img in imgs
    return img.Url if img.Id is imgId
  
# 下载图片
downloadImg = (url)->

# 解析单篇文章
parsePost = (post)->

# 获取文章的元信息
getPostMetaInfo = (post)->
  metaInfo =[
    'title: ' + blogInfo.Title
    'date: ' + formatTime blogInfo.CreateTime
    'updated: ' + formatTime blogInfo.ModifiedCreateTime
    'tags: ' + getBlogTags blogInfo.Tags
    'uri: ' + getBlogUri blogInfo.Uri
  ]
  metaInfo.join '\n'

# 解析文章数据
parsePosts = (posts)->
  posts.forEach parsePost


# 主函数
main = ->
  args = process.argv.slice 2
  # console.log 'started'
  # rss 地址
  rssPath = args[0]
  # 文章保存地址
  savePath = args[1]

  unless rssPath
    console.log 'rssPath or blog path must be specified'
    return

  isOnlineRss = false
  # 如果给定的是在线网址
  if /^http:\/\/.+$/.test rssPath
    # 获取实际的下载地址
    rssPath = /^(http:\/\/[^\/]+)$/.exec(rssPath)[1] + '/rss'
    isOnlineRss = true
  # 如果给定的是博客id
  else if /^[\w-]+$/.test rssPath
    rssPath = "#http://{rssPath}.diandian.com/rss"
    isOnlineRss = true
  
  # 未指定文章地址
  unless savePath
    # 在线的话使用工具脚本所在目录
    if isOnlineRss
      savePath = path.dirname __filename + '/posts'
    # 否则使用rss文件所在目录
    else
      savePath = path.dirname rssPath + '/posts'

  getContentFrom rssPath, parseRss

do main    
