# Gb
GB是针对GitLab开发的一款管理工具，使用ruby开发，简化对多个git版本库的管理，方便代码同步及代码提交review。

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gb

## Usage

### 1、创建gb配置文件Gb.yml
```ruby
#创建本地文件Gb.yml，根据提示输入Gitlab的private token
gb create

#或通过在线url地址下载Gb.yml
gb create --config_url=[url]
```

### 2、gb初始化，下载代码
```ruby
gb init
```

### 3、开启gb工作区
开启gb工作区，指定本地工作分支名称和远程跟踪分支\
--force选项可以忽略工作分支存在校验
```ruby
gb start dev-v3.10.0 dev
```

### 4、同步工作区代码
开启工作区以后，通过
```ruby
gb sync
```
可以把远程分支代码同步到本地工作区，实现代码更新

### 4、提交review
当您本地git提交代码到本地工作分支，需要提交merge request时，通过命令
```ruby
gb review
```
自动同步本地工作分支代码到远程，并提交merge request

### 5、其他命令
```ruby
#查看本地工作区信息
gb workspace

#查看本地代码提交情况，类似git status
gb status

#提交merge request，可以自由指定发起merge的分支，并且不会同步本地代码
gb merge dev master

#遍历工作执行命令
gb forall --c="git pull"

#创建远程tag
gb create-tag master release_v3.9.1

#删除远程tag
gb delete-tag release_v3.9.1
 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/luobin23628/gb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Gb project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/gb/blob/master/CODE_OF_CONDUCT.md).
