# diandian to markdown
将点点网站备份的文件(xml)转换为markdown文件, 一篇文章一份markdown, 完整转换xml中的信息, 包括音频, 并且会尝试下载文章中用到的图片. 图片会依据图片上传的年份及月份分目录存放.

目前视频无法完全转换, 需要提供视频数据样本 = =

程序会提取出博客的信息至 `blog-meta.yml` 文件中, 每篇博客的markdown文件开头会添加文章的 `frontmatter` 信息.

通过本程序转换得到的markdown文件, 非常适合再结合 <https://hexo.io/> 等静态博客生成工具来再次生成你自己的博客.

## 准备工作

1. 备份博客: 在[点点网](http://http://www.diandian.com/)可以访问时, 登录网站, 打开[备份页面](http://www.diandian.com/backup), 选择要备份的博客, 备份
2. 安装 nodejs, 下载整个代码仓库并解压
3. 在命令行中将工作路径切换至下载的代码仓库所在路径, 再先后执行下列命令
  
  ```
  npm install -g coffee-script
  npm install
  ```

## 使用方法

## 转换xml为markdown

```
coffee dd2md.coffee <xml-path> <output-directory>
```
`<output-directory>` 可省略, 默认存放在 与 xml 相同路径下的 < blogname > - posts 文件夹下


如 博客地址为 <http://love.diandian.com>, 那博客名为 love.  
使用下列命令备份, 文件将输出至 `~/Download/love-posts`目录下

```
coffee dd2md.coffee ~/Download/diandian-blog-backup-love.xml
```

## 重新下载下载失败的图片
由于点点网站并不稳定, 所有图片可能无法一次完全下载成功, 有些图片可能已经被删除. 可以使用下述命令尝试重新下载下载失败的图片

```
coffee dd2md.coffee <xml-path> <output-directory> -i
```

## 清理文章中下载失败的图片
如果多次尝试重新下载图片均不成功， 八成图片已经不在这个地球上了。如果你的markdown是用来生成静态网站的，那么网站中引入不存在的图片会大大拖慢网站的加载速度。你可以用本命令清理markdown文件中以及images文件夹中不存在的图片。

```
coffee dd2md.coffee <output-directory> -c
```

