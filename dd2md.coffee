
path = require 'path'
fs = require 'fs'
http = require 'http'
mkdirp = require 'mkdirp'
toMarkdown = require 'to-markdown'
util = require 'util'
{parseString} = require 'xml2js'



# 生成文件的存储地址
saveDir = ''

# 给数字添加前置0
prefix0 = (n, len = 2)->
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
formatTime = (timeStamp, format='yyyy-MM-dd hh:mm:ss')->
  t = new Date +timeStamp
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
    yy: prefix0 t.getYear() % 100
    yyyy: t.getFullYear()
    MM: prefix0 M
    M: M
    dd: prefix0 D
    d: D
    hh: prefix0 H
    h: H
    mm: prefix0 m
    m: m
    ss: prefix0 s
    s: s
    ms: ms

  format.replace /[a-z]+/ig, ($0)->
    tt[ $0 ] ? $0

# 获取文件内容
getContentFrom = (url, done)->
  fs.readFile url, (error, str)->
    if error
      console.error "can not read file <#{url}> because of #{error.message}"
    else
      parseString str, {explicitArray: false}, (error, xml)->
        if error
          console.error "failed to parse xml content because of #{error.message}"
        else
          xml = xml.DiandianBlogBackup
          # 未指定文章地址
          unless saveDir
            saveDir = path.dirname rssPath
            saveDir += "/#{xml.BlogInfo.BlogUrl}-posts"
          done xml

    return

# 解析rss内容
parseRss = (xml)->
  getImageUrl.imgs = xml.Images.Image

  getBlogMeta xml.BlogInfo

  parsePosts xml.Posts.Post


# 获取博客基础信息, 输出至yaml
getBlogMeta = (blogInfo)->
  downloadImg blogInfo.BlogPic, 'blog-logo'
  metaInfo = [
    'title: ' + blogInfo.BlogName
    'description: ' + blogInfo.BlogDesc.replace /[\r\n]/g, ' '
  ]
  mkdirp.sync saveDir
  fs.writeFile "#{saveDir}/blog-meta.yml", metaInfo.join('\n'), (error)->
    if error
      console.log "[error] failed to save <blog-meta.yml>, because of <#{error.message}>"
    else
      console.log '[success] <blog-meta.yml> saved'
 

# 根据图片id查找图片
getImageUrl = (imgId)->
  imgs = getImageUrl.imgs
  for img in imgs
    return img.Url if img.Id is imgId
  
# 下载图片
# 返回处理后的图片相对路径, 供markdown作为图片地址使用
downloadImg = (imgId, createdTime, savePath)->
  if savePath
    savePath = "images/#{formatTime(createdTime, 'yyyy/MM')}/#{savePath}"
  else
    savePath = createdTime

  url = if /^[\w-]+$/.test(imgId) then getImageUrl(imgId) else imgId
  unless url
    console.log "[error] can not find the image with id <#{imgId}>"
    return
  # 获取url中的文件后缀
  matches = /\/[^\/]+\.([\w]+)$/.exec url
  # url中能匹配到后缀, 且图片保存地址无后缀
  if matches and not (new RegExp("#{matches[1]}$").test(savePath))
    savePath += ".#{matches[1].toLowerCase()}"
  filePath = "#{saveDir}/#{savePath}"
  
  downloadFile url, filePath

  savePath

# 下载文件
downloadFile = (url, filePath)->
  mkdirp.sync path.dirname filePath
  
  console.log "[info]start to download image <#{url}>"

  file = fs.createWriteStream filePath
  http.get url, (response)->
    response.pipe file
  .on 'error', (error)->
    console.log "[error] failed to download image <#{url}>"

# 解析文章数据
parsePosts = (posts)->
  posts.forEach parsePost
  # parsePost posts[9]


# 解析单篇文章
parsePost = (post)->
  blogContent = getPostMetaInfo(post) + '\n---\n\n'
  text = ''
  switch post.PostType
    when 'text'
      text = html2Md post.Text, post.CreateTime
    when 'photo'
      text = html2Md(post.Desc, post.CreateTime) + '\n\n'
      photos = if Array.isArray(post.PhotoItem) then post.PhotoItem else [ post.PhotoItem ]
      text += photos.map (photo)->
        imgId2Md photo.Id, post.CreateTime, photo.Desc
      .join '\n\n'
    when 'audio'
      text = "by #{post.ArtistName}\n\n" if post.ArtistName
      text += imgId2Md(post.Cover, post.CreateTime) + '\n\n'
      text += ['<object width="257" height="33" type="application/x-shockwave-flash" data="http://img.xiami.com/widget/0_' + post.SongId + '_/singlePlayer.swf">'
        '<param value="http://img.xiami.com/widget/0_' + post.SongId + '_/singlePlayer.swf" name="movie">'
        '<param value="transparent" name="wmode">'
        '<param value="high" name="quality">'
        '<param name="allowScriptAccess" value="always">'
        '</object>'].join('') + '\n\n'
      text += html2Md(post.Comment, post.CreateTime) + '\n\n'
    when 'useraudio'
      text = "by #{post.ArtistName}\n\n" if post.ArtistName

  blogContent += text
  blogTitle = post.Title or post.SongName
  filePath = "#{saveDir}/#{formatTime(post.CreateTime, 'yyyy-MM-dd')}-#{blogTitle}.md"
  fs.writeFile filePath, blogContent, (error)->
    if error
      console.log "[error] failed to save blog <#{blogTitle}>, because of <#{error.message}>"
    else
      console.log "[success] blog <#{blogTitle}> saved"


# 把html转换为markdown
html2Md = (html, createTime)->
  toMarkdown html,
    gfm: true
    converters:[
      {
        filter: 'img'
        replacement: (content, node)->
          imgId2Md node.id, createTime, node.title
      }
    ]


# 把点点的图片id 转换为 markdown格式
# 并将图片下载至本地
imgId2Md = (imgId, createdTime, desc="")->
  if /^[\w-]+$/.test imgId
    url = getImageUrl imgId
    fileName = imgId
  else
    url = imgId
    # 提取url中的数字, 将 / 转换为 - 作为分隔符, 并去掉首尾的 - , 最终得到的字符串作为文件名
    # http://abc.com/2323/we90/44.html => 2323-90-44
    fileName = url.replace(/[^\d\/]/g, '').replace(/\//g, '-').replace(/(^-+|-+$)/g, '')
  return '' unless url
  savePath = downloadImg url, createdTime, fileName
  "![#{desc}](./#{savePath})"

# 获取文章的元信息
getPostMetaInfo = (post)->
  metaInfo =[
    'title: ' + (post.Title or post.SongName)
    'date: ' + formatTime post.CreateTime
    'updated: ' + formatTime post.ModifiedCreateTime
    'tags: ' + getBlogTags post.Tags
    'uri: ' + getBlogUri post.Uri
  ]
  metaInfo.join '\n'


# 获取标签信息
getBlogTags = (tags)->
  console.log 'tags: ' + JSON.stringify tags
  return '' unless tags
  tags = tags.Tag
  tags = [tags] unless Array.isArray tags
  '\n - ' + tags.join '\n - '

# 获取博客自定义的uri
getBlogUri = (uri)->
  return '' unless uri
  /([^\/]+)$/.exec(uri)[1]

# 重新下载图片
redownloadImgs = (xml)->
  imgs = xml.Images.Image
  unless imgs.length
    console.log "[info]nothing need to redownload"
    return

  imgs.forEach redownloadImg

# 重新下载单张图片
redownloadImg = (img)->
  url = img.Url
  fileName = img.Id + '.' + /\.(\w+)$/.exec(url)[1].toLowerCase()
  matches = /\/d\/([\d]{4})\/([\d]{2})/.exec url
  unless matches
    console.log "[error] can not find image's <#{url}> date info"
    return
  filePath = "#{saveDir}/images/#{matches[1]}/#{matches[2]}/#{fileName}"
  try
    stats = util.inspect fs.statSync filePath
    return if stats.size > 1024 * 4
    fs.unlinkSync filePath
  catch e
    # console.log "[error] file e.message"
  
  console.log "[info]restart to download image <#{url}> to <#{filePath}>"
  downloadFile url, filePath
  
  


# 主函数
main = ->
  args = process.argv.slice 2
  
  cmd = ''
  # 提取出命令字 以 - 开头
  for v, k in args
    if v[0] is '-'
      cmd = v.slice 1
      args.splice k, 1
      break
  # rss 地址
  rssPath = args[0]
  # 文章保存地址
  saveDir = args[1]

  unless rssPath
    console.log 'rssPath or blog path must be specified'
    return
  # 命令i表示重新下载未成功下载的图片
  if cmd is 'i'
    getContentFrom rssPath, redownloadImgs
  else
    getContentFrom rssPath, parseRss
  

do main    
