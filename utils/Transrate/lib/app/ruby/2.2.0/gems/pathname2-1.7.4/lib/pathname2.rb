# == Synopsis
#
# Pathname represents a path name on a filesystem. A Pathname can be
# relative or absolute.  It does not matter whether the path exists or not.
#
# All functionality from File, FileTest, and Dir is included, using a facade
# pattern.
#
# This class works on both Unix and Windows, including UNC path names. Note
# that forward slashes are converted to backslashes on Windows systems.
#
# == Usage
#
# require "pathname2"
#
# # Unix
# path1 = Pathname.new("/foo/bar/baz")
# path2 = Pathname.new("../zap")
#
# path1 + path2 # "/foo/bar/zap"
# path1.dirname # "/foo/bar"
#
# # Windows
# path1 = Pathname.new("C:\\foo\\bar\\baz")
# path2 = Pathname.new("..\\zap")
#
# path1 + path2 # "C:\\foo\\bar\\zap"
# path1.exists? # Does the path exist?
#
require 'facade'
require 'fileutils'
require 'pp'

if File::ALT_SEPARATOR
  require 'ffi'
  class String
    # Convenience method for converting strings to UTF-16LE for wide character
    # functions that require it.
    def wincode
      if self.encoding.name != 'UTF-16LE'
        temp = self.dup
        (temp.tr(File::SEPARATOR, File::ALT_SEPARATOR) << 0.chr).encode('UTF-16LE')
      end
    end
  end
end

# You're mine now.
Object.send(:remove_const, :Pathname) if defined?(Pathname)

class Pathname < String
  class Error < StandardError; end
  extend Facade

  undef_method :pretty_print

  facade File, File.methods(false).map{ |m| m.to_sym } - [
    :chmod, :lchmod, :chown, :lchown, :dirname, :fnmatch, :fnmatch?,
    :link, :open, :realpath, :rename, :symlink, :truncate, :utime,
    :basename, :expand_path, :join
  ]

  facade Dir, Dir.methods(false).map{ |m| m.to_sym } - [
    :chdir, :entries, :glob, :foreach, :mkdir, :open
  ]

  private

  alias :_plus_ :+ # Used to prevent infinite loops in some cases

  if File::ALT_SEPARATOR
    extend FFI::Library
    ffi_lib :shlwapi

    attach_function :PathAppendW, [:pointer, :pointer], :bool
    attach_function :PathCanonicalizeW, [:pointer, :buffer_in], :bool
    attach_function :PathCreateFromUrlW, [:buffer_in, :pointer, :pointer, :ulong], :long
    attach_function :PathGetDriveNumberW, [:buffer_in], :int
    attach_function :PathIsRelativeW, [:buffer_in], :bool
    attach_function :PathIsRootW, [:buffer_in], :bool
    attach_function :PathIsUNCW, [:buffer_in], :bool
    attach_function :PathIsURLW, [:buffer_in], :bool
    attach_function :PathRemoveBackslashW, [:buffer_in], :pointer
    attach_function :PathStripToRootW, [:pointer], :bool
    attach_function :PathUndecorateW, [:pointer], :void

    ffi_lib :kernel32

    attach_function :GetLongPathNameW, [:buffer_in, :buffer_out, :ulong], :ulong
    attach_function :GetShortPathNameW, [:buffer_in, :pointer, :ulong], :ulong
  end

  public

  # The version of the pathname2 library
  VERSION = '1.7.4'

  # The maximum length of a path
  MAXPATH = 1024 unless defined? MAXPATH # Yes, I willfully violate POSIX

  # Returns the expanded path of the current working directory.
  #
  # Synonym for Pathname.new(Dir.pwd).
  #
  def self.pwd
    new(Dir.pwd)
  end

  class << self
    alias getwd pwd
  end

  # Creates and returns a new Pathname object.
  #
  # On platforms that define File::ALT_SEPARATOR, all forward slashes are
  # replaced with the value of File::ALT_SEPARATOR. On MS Windows, for
  # example, all forward slashes are replaced with backslashes.
  #
  # File URL's will be converted to Pathname objects, e.g. the file URL
  # "file:///C:/Documents%20and%20Settings" will become 'C:\Documents and Settings'.
  #
  # Examples:
  #
  #   Pathname.new("/foo/bar/baz")
  #   Pathname.new("foo")
  #   Pathname.new("file:///foo/bar/baz")
  #   Pathname.new("C:\\Documents and Settings\\snoopy")
  #
  def initialize(path)
    if path.length > MAXPATH
      msg = "string too long.  maximum string length is " + MAXPATH.to_s
      raise ArgumentError, msg
    end

    @sep = File::ALT_SEPARATOR || File::SEPARATOR
    @win = File::ALT_SEPARATOR

    # Handle File URL's. The separate approach for Windows is necessary
    # because Ruby's URI class does not (currently) parse absolute file URL's
    # properly when they include a drive letter.
    if @win
      wpath = path.wincode

      if PathIsURLW(wpath)
        buf = FFI::MemoryPointer.new(:char, MAXPATH)
        len = FFI::MemoryPointer.new(:ulong)
        len.write_ulong(buf.size)

        if PathCreateFromUrlW(wpath, buf, len, 0) == 0
          path = buf.read_string(path.size * 2).tr(0.chr, '')
        else
          raise Error, "invalid file url: #{path}"
        end
      end
    else
      if path.index('file:///', 0)
        require 'uri'
        path = URI::Parser.new.unescape(path)[7..-1]
      end
    end

    # Convert forward slashes to backslashes on Windows
    path = path.tr(File::SEPARATOR, File::ALT_SEPARATOR) if @win

    super(path)
  end

  # Returns a real (absolute) pathname of +self+ in the actual filesystem.
  #
  # Unlike most Pathname methods, this one assumes that the path actually
  # exists on your filesystem. If it doesn't, an error is raised. If a
  # circular symlink is encountered a system error will be raised.
  #
  # Example:
  #
  #    Dir.pwd                      # => /usr/local
  #    File.exists?('foo')          # => true
  #    Pathname.new('foo').realpath # => /usr/local/foo
  #
  def realpath
    File.stat(self) # Check to ensure that the path exists

    if File.symlink?(self)
      file = self.dup

      while true
        file = File.join(File.dirname(file), File.readlink(file))
        break unless File.symlink?(file)
      end

      self.class.new(file).clean
    else
      self.class.new(Dir.pwd) + self
    end
  end

  # Returns the children of the directory, files and subdirectories, as an
  # array of Pathname objects. If you set +with_directory+ to +false+, then
  # the returned pathnames will contain the filename only.
  #
  # Note that the result never contain the entries '.' and '..' in the
  # the directory because they are not children. Also note that this method
  # is *not* recursive.
  #
  # Example:
  #
  # path = Pathname.new('/usr/bin')
  # path.children        # => ['/usr/bin/ruby', '/usr/bin/perl', ...]
  # path.children(false) # => ['ruby', 'perl', ...]
  #
  def children(with_directory = true)
    with_directory = false if self == '.'
    result = []
    Dir.foreach(self) { |file|
      next if file == '.' || file == '..'
      if with_directory
        result << self.class.new(File.join(self, file))
      else
        result << self.class.new(file)
      end
    }
    result
  end

  # Windows only
  #
  # Removes the decoration from a path string. Non-destructive.
  #
  # Example:
  #
  # path = Pathname.new('C:\Path\File[5].txt')
  # path.undecorate # => C:\Path\File.txt.
  #
  def undecorate
    unless @win
      raise NotImplementedError, "not supported on this platform"
    end

    wpath = FFI::MemoryPointer.from_string(self.wincode)

    PathUndecorateW(wpath)

    self.class.new(wpath.read_string(wpath.size).split("\000\000").first.tr(0.chr, ''))
  end

  # Windows only
  #
  # Performs the substitution of Pathname#undecorate in place.
  #
  def undecorate!
    self.replace(undecorate)
  end

  # Windows only
  #
  # Returns the short path for a long path name.
  #
  # Example:
  #
  #    path = Pathname.new('C:\Program Files\Java')
  #    path.short_path # => C:\Progra~1\Java.
  #
  def short_path
    raise NotImplementedError, "not supported on this platform" unless @win

    buf = FFI::MemoryPointer.new(:char, MAXPATH)
    wpath = self.wincode

    size = GetShortPathNameW(wpath, buf, buf.size)

    raise SystemCallError.new('GetShortPathName', FFI.errno) if size == 0

    self.class.new(buf.read_bytes(size * 2).delete(0.chr))
  end

  # Windows only
  #
  # Returns the long path for a long path name.
  #
  # Example:
  #
  #    path = Pathname.new('C:\Progra~1\Java')
  #    path.long_path # => C:\Program Files\Java.
  #
  def long_path
    raise NotImplementedError, "not supported on this platform" unless @win

    buf = FFI::MemoryPointer.new(:char, MAXPATH)
    wpath = self.wincode

    size = GetLongPathNameW(wpath, buf, buf.size)

    raise SystemCallError.new('GetShortPathName', FFI.errno) if size == 0

    self.class.new(buf.read_bytes(size * 2).delete(0.chr))
  end

  # Removes all trailing slashes, if present. Non-destructive.
  #
  # Example:
  #
  #    path = Pathname.new('/usr/local/')
  #    path.pstrip # => '/usr/local'
  #
  def pstrip
    str = self.dup
    return str if str.empty?

    while ["/", "\\"].include?(str.to_s[-1].chr)
      str.strip!
      str.chop!
    end

    self.class.new(str)
  end

  # Performs the substitution of Pathname#pstrip in place.
  #
  def pstrip!
    self.replace(pstrip)
  end

  # Splits a pathname into strings based on the path separator.
  #
  # Examples:
  #
  #    Pathname.new('/usr/local/bin').to_a # => ['usr', 'local', 'bin']
  #    Pathname.new('C:\WINNT\Fonts').to_a # => ['C:', 'WINNT', 'Fonts']
  #
  def to_a
    # Split string by path separator
    if @win
      array = tr(File::SEPARATOR, File::ALT_SEPARATOR).split(@sep)
    else
      array = split(@sep)
    end
    array.delete("")    # Remove empty elements
    array
  end

  # Yields each component of the path name to a block.
  #
  # Example:
  #
  #    Pathname.new('/usr/local/bin').each{ |element|
  #       puts "Element: #{element}"
  #    }
  #
  #    Yields 'usr', 'local', and 'bin', in turn
  #
  def each
    to_a.each{ |element| yield element }
  end

  # Returns the path component at +index+, up to +length+ components, joined
  # by the path separator. If the +index+ is a Range, then that is used
  # instead and the +length+ is ignored.
  #
  # Keep in mind that on MS Windows the drive letter is the first element.
  #
  # Examples:
  #
  #    path = Pathname.new('/home/john/source/ruby')
  #    path[0]    # => 'home'
  #    path[1]    # => 'john'
  #    path[0, 3] # => '/home/john/source'
  #    path[0..1] # => '/home/john'
  #
  #    path = Pathname.new('C:/Documents and Settings/John/Source/Ruby')
  #    path[0]    # => 'C:\'
  #    path[1]    # => 'Documents and Settings'
  #    path[0, 3] # => 'C:\Documents and Settings\John'
  #    path[0..1] # => 'C:\Documents and Settings'
  #
  def [](index, length=nil)
    if index.is_a?(Fixnum)
      if length
        path = File.join(to_a[index, length])
      else
        path = to_a[index]
      end
    elsif index.is_a?(Range)
      if length
        warn 'Length argument ignored'
      end
      path = File.join(to_a[index])
    else
      raise TypeError, "Only Fixnums and Ranges allowed as first argument"
    end

    if path && @win
      path = path.tr("/", "\\")
    end

    path
  end

  # Yields each component of the path, concatenating the next component on
  # each iteration as a new Pathname object, starting with the root path.
  #
  # Example:
  #
  #    path = Pathname.new('/usr/local/bin')
  #
  #    path.descend{ |name|
  #       puts name
  #    }
  #
  #    First iteration  => '/'
  #    Second iteration => '/usr'
  #    Third iteration  => '/usr/local'
  #    Fourth iteration => '/usr/local/bin'
  #
  def descend
    if root?
      yield root
      return
    end

    if @win
      path = unc? ? "#{root}\\" : ""
    else
      path = absolute? ? root : ""
    end

    # Yield the root directory if an absolute path (and not Windows)
    unless @win && !unc?
      yield root if absolute?
    end

    each{ |element|
      if @win && unc?
        next if root.to_a.include?(element)
      end
      path << element << @sep
      yield self.class.new(path.chop)
    }
  end

  # Yields the path, minus one component on each iteration, as a new
  # Pathname object, ending with the root path.
  #
  # Example:
  #
  #    path = Pathname.new('/usr/local/bin')
  #
  #    path.ascend{ |name|
  #       puts name
  #    }
  #
  #    First iteration  => '/usr/local/bin'
  #    Second iteration => '/usr/local'
  #    Third iteration  => '/usr'
  #    Fourth iteration => '/'
  #
  def ascend
    if root?
      yield root
      return
    end

    n = to_a.length

    while n > 0
      path = to_a[0..n-1].join(@sep)
      if absolute?
        if @win && unc?
          path = "\\\\" << path
        end
        unless @win
          path = root << path
        end
      end

      path = self.class.new(path)
      yield path

      if @win && unc?
        break if path.root?
      end

      n -= 1
    end

    # Yield the root directory if an absolute path (and not Windows)
    unless @win
      yield root if absolute?
    end
  end

  # Returns the root directory of the path, or '.' if there is no root
  # directory.
  #
  # On Unix, this means the '/' character. On Windows, this can refer
  # to the drive letter, or the server and share path if the path is a
  # UNC path.
  #
  # Examples:
  #
  #    Pathname.new('/usr/local').root       # => '/'
  #    Pathname.new('lib').root              # => '.'
  #
  #    On MS Windows:
  #
  #    Pathname.new('C:\WINNT').root         # => 'C:'
  #    Pathname.new('\\some\share\foo').root # => '\\some\share'
  #
  def root
    dir = "."

    if @win
      wpath = FFI::MemoryPointer.from_string(self.wincode)
      if PathStripToRootW(wpath)
        dir = wpath.read_string(wpath.size).split("\000\000").first.tr(0.chr, '')
      end
    else
      dir = "/" if self =~ /^\//
    end

    self.class.new(dir)
  end

  # Returns whether or not the path consists only of a root directory.
  #
  # Examples:
  #
  #   Pathname.new('/').root?    # => true
  #   Pathname.new('/foo').root? # => false
  #
  def root?
    if @win
      PathIsRootW(self.wincode)
    else
      self == root
    end
  end

  # MS Windows only
  #
  # Determines if the string is a valid Universal Naming Convention (UNC)
  # for a server and share path.
  #
  # Examples:
  #
  #    Pathname.new("\\\\foo\\bar").unc?     # => true
  #    Pathname.new('C:\Program Files').unc? # => false
  #
  def unc?
    raise NotImplementedError, "not supported on this platform" unless @win
    PathIsUNCW(self.wincode)
  end

  # MS Windows only
  #
  # Returns the drive number that corresponds to the root, or nil if not
  # applicable.
  #
  # Example:
  #
  #    Pathname.new("C:\\foo").drive_number # => 2
  #
  def drive_number
    unless @win
      raise NotImplementedError, "not supported on this platform"
    end

    num = PathGetDriveNumberW(self.wincode)
    num >= 0 ? num : nil
  end

  # Compares two Pathname objects.  Note that Pathnames may only be compared
  # against other Pathnames, not strings. Otherwise nil is returned.
  #
  # Example:
  #
  #    path1 = Pathname.new('/usr/local')
  #    path2 = Pathname.new('/usr/local')
  #    path3 = Pathname.new('/usr/local/bin')
  #
  #    path1 <=> path2 # => 0
  #    path1 <=> path3 # => -1
  #
  def <=>(string)
    return nil unless string.kind_of?(Pathname)
    super
  end

  # Returns the parent directory of the given path.
  #
  # Example:
  #
  #    Pathname.new('/usr/local/bin').parent # => '/usr/local'
  #
  def parent
    return self if root?
    self + ".." # Use our custom '+' method
  end

  # Returns a relative path from the argument to the receiver. If +self+
  # is absolute, the argument must be absolute too. If +self+ is relative,
  # the argument must be relative too. For relative paths, this method uses
  # an imaginary, common parent path.
  #
  # This method does not access the filesystem. It assumes no symlinks.
  # You should only compare directories against directories, or files against
  # files, or you may get unexpected results.
  #
  # Raises an ArgumentError if it cannot find a relative path.
  #
  # Examples:
  #
  #    path = Pathname.new('/usr/local/bin')
  #    path.relative_path_from('/usr/bin') # => "../local/bin"
  #
  #    path = Pathname.new("C:\\WINNT\\Fonts")
  #    path.relative_path_from("C:\\Program Files") # => "..\\WINNT\\Fonts"
  #
  def relative_path_from(base)
    base = self.class.new(base) unless base.kind_of?(Pathname)

    if self.absolute? != base.absolute?
      raise ArgumentError, "relative path between absolute and relative path"
    end

    return self.class.new(".") if self == base
    return self if base == "."

    # Because of the way the Windows version handles Pathname#clean, we need
    # a little extra help here.
    if @win
      if root != base.root
        msg = 'cannot determine relative paths from different root paths'
        raise ArgumentError, msg
      end
      if base == '..' && (self != '..' || self != '.')
        raise ArgumentError, "base directory may not contain '..'"
      end
    end

    dest_arr = self.clean.to_a
    base_arr = base.clean.to_a
    dest_arr.delete('.')
    base_arr.delete('.')

    # diff_arr = dest_arr - base_arr

    while !base_arr.empty? && !dest_arr.empty? && base_arr[0] == dest_arr[0]
      base_arr.shift
      dest_arr.shift
    end

    if base_arr.include?("..")
      raise ArgumentError, "base directory may not contain '..'"
    end

    base_arr.fill("..")
    rel_path = base_arr + dest_arr

    if rel_path.empty?
      self.class.new(".")
    else
      self.class.new(rel_path.join(@sep))
    end
  end

  # Adds two Pathname objects together, or a Pathname and a String. It
  # also automatically cleans the Pathname.
  #
  # Adding a root path to an existing path merely replaces the current
  # path. Adding '.' to an existing path does nothing.
  #
  # Example:
  #
  #    path1 = '/foo/bar'
  #    path2 = '../baz'
  #    path1 + path2 # '/foo/baz'
  #
  def +(string)
    unless string.kind_of?(Pathname)
      string = self.class.new(string)
    end

    # Any path plus "." is the same directory
    return self if string == "."
    return string if self == "."

    # Use the builtin PathAppend() function if on Windows - much easier
    if @win
      path = FFI::MemoryPointer.new(:char, MAXPATH)
      path.write_string(self.dup.wincode)
      more = FFI::MemoryPointer.from_string(string.wincode)

      PathAppendW(path, more)

      path = path.read_string(path.size).split("\000\000").first.delete(0.chr)

      return self.class.new(path) # PathAppend cleans automatically
    end

    # If the string is an absolute directory, return it
    return string if string.absolute?

    array = to_a + string.to_a
    new_string = array.join(@sep)

    unless relative? || @win
      temp = @sep + new_string # Add root path back if needed
      new_string.replace(temp)
    end

    self.class.new(new_string).clean
  end

  alias :/ :+

  # Returns whether or not the path is an absolute path.
  #
  # Example:
  #
  #    Pathname.new('/usr/bin').absolute? # => true
  #    Pathname.new('usr').absolute?      # => false
  #
  def absolute?
    !relative?
  end

  # Returns whether or not the path is a relative path.
  #
  # Example:
  #
  #    Pathname.new('/usr/bin').relative? # => true
  #    Pathname.new('usr').relative?      # => false
  #
  def relative?
    if @win
      PathIsRelativeW(self.wincode)
    else
      root == "."
    end
  end

  # Removes unnecessary '.' paths and ellides '..' paths appropriately.
  # This method is non-destructive.
  #
  # Example:
  #
  #    path = Pathname.new('/usr/./local/../bin')
  #    path.clean # => '/usr/bin'
  #
  def clean
    return self if self.empty?

    if @win
      ptr = FFI::MemoryPointer.new(:char, MAXPATH)
      if PathCanonicalizeW(ptr, self.wincode)
        return self.class.new(ptr.read_string(ptr.size).delete(0.chr))
      else
        return self
      end
    end

    final = []

    to_a.each{ |element|
      next if element == "."
      final.push(element)
      if element == ".." && self != ".."
        2.times{ final.pop }
      end
    }

    final = final.join(@sep)
    final = root._plus_(final) if root != "."
    final = "." if final.empty?

    self.class.new(final)
  end

  alias :cleanpath :clean

  # Identical to Pathname#clean, except that it modifies the receiver
  # in place.
  #
  def clean!
    self.replace(clean)
  end

  alias cleanpath! clean!

  # Similar to File.dirname, but this method allows you to specify the number
  # of levels up you wish to refer to.
  #
  # The default level is 1, i.e. it works the same as File.dirname. A level of
  # 0 will return the original path. A level equal to or greater than the
  # number of path elements will return the root path.
  #
  # A number less than 0 will raise an ArgumentError.
  #
  # Example:
  #
  #    path = Pathname.new('/usr/local/bin/ruby')
  #
  #    puts path.dirname    # => /usr/local/bin
  #    puts path.dirname(2) # => /usr/local
  #    puts path.dirname(3) # => /usr
  #    puts path.dirname(9) # => /
  #
  def dirname(level = 1)
    raise ArgumentError if level < 0
    local_path = self.dup

    level.times{ |n| local_path = File.dirname(local_path) }
    self.class.new(local_path)
  end

  # Joins the given pathnames onto +self+ to create a new Pathname object.
  #
  #  path = Pathname.new("C:/Users")
  #  path = path.join("foo", "Downloads") # => C:/Users/foo/Downloads
  #
  def join(*args)
    args.unshift self
    result = args.pop
    result = self.class.new(result) unless result === self.class
    return result if result.absolute?

    args.reverse_each{ |path|
      path = self.class.new(path) unless path === self.class
      result = path + result
      break if result.absolute?
    }

    result
  end

  # A custom pretty printer
  def pretty_print(q)
    if File::ALT_SEPARATOR
      q.text(self.to_s.tr(File::SEPARATOR, File::ALT_SEPARATOR))
    else
      q.text(self.to_s)
    end
  end

  #-- Find facade

  # Pathname#find is an iterator to traverse a directory tree in a depth first
  # manner. It yields a Pathname for each file under the directory passed to
  # Pathname.new.
  #
  # Since it is implemented by the Find module, Find.prune can be used to
  # control the traverse.
  #
  # If +self+ is ".", yielded pathnames begin with a filename in the current
  # current directory, not ".".
  #
  def find(&block)
    require "find"
    if self == "."
      Find.find(self){ |f| yield self.class.new(f.sub(%r{\A\./}, '')) }
    else
      Find.find(self){ |f| yield self.class.new(f) }
    end
  end

  #-- IO methods not handled by facade

  # IO.foreach
  def foreach(*args, &block)
    IO.foreach(self, *args, &block)
  end

  # IO.read
  def read(*args)
    IO.read(self, *args)
  end

  # IO.readlines
  def readlines(*args)
    IO.readlines(self, *args)
  end

  # IO.sysopen
  def sysopen(*args)
    IO.sysopen(self, *args)
  end

  #-- Dir methods not handled by facade

  # Dir.glob
  #
  # :no-doc:
  # This differs from Tanaka's implementation in that it does a temporary
  # chdir to the path in question, then performs the glob.
  #
  def glob(*args)
    Dir.chdir(self){
      if block_given?
        Dir.glob(*args){ |file| yield self.class.new(file) }
      else
        Dir.glob(*args).map{ |file| self.class.new(file) }
      end
    }
  end

  # Dir.chdir
  def chdir(&block)
    Dir.chdir(self, &block)
  end

  # Dir.entries
  def entries
    Dir.entries(self).map{ |file| self.class.new(file) }
  end

  # Dir.mkdir
  def mkdir(*args)
    Dir.mkdir(self, *args)
  end

  # Dir.opendir
  def opendir(&block)
    Dir.open(self, &block)
  end

  #-- File methods not handled by facade

  # File.chmod
  def chmod(mode)
    File.chmod(mode, self)
  end

  # File.lchmod
  def lchmod(mode)
    File.lchmod(mode, self)
  end

  # File.chown
  def chown(owner, group)
    File.chown(owner, group, self)
  end

  # File.lchown
  def lchown(owner, group)
    File.lchown(owner, group, self)
  end

  # File.fnmatch
  def fnmatch(pattern, *args)
    File.fnmatch(pattern, self, *args)
  end

  # File.fnmatch?
  def fnmatch?(pattern, *args)
    File.fnmatch?(pattern, self, *args)
  end

  # File.link
  def link(old)
    File.link(old, self)
  end

  # File.open
  def open(*args, &block)
    File.open(self, *args, &block)
  end

  # File.rename
  def rename(name)
    File.rename(self, name)
  end

  # File.symlink
  def symlink(old)
    File.symlink(old, self)
  end

  # File.truncate
  def truncate(length)
    File.truncate(self, length)
  end

  # File.utime
  def utime(atime, mtime)
    File.utime(atime, mtime, self)
  end

  # File.basename
  def basename(*args)
    self.class.new(File.basename(self, *args))
  end

  # File.expand_path
  def expand_path(*args)
    self.class.new(File.expand_path(self, *args))
  end

  #--
  # FileUtils facade.  Note that methods already covered by File and Dir
  # are not defined here (pwd, mkdir, etc).
  #++

  # FileUtils.cd
  def cd(*args, &block)
    FileUtils.cd(self, *args, &block)
  end

  # FileUtils.mkdir_p
  def mkdir_p(*args)
    FileUtils.mkdir_p(self, *args)
  end

  alias mkpath mkdir_p

  # FileUtils.ln
  def ln(*args)
    FileUtils.ln(self, *args)
  end

  # FileUtils.ln_s
  def ln_s(*args)
    FileUtils.ln_s(self, *args)
  end

  # FileUtils.ln_sf
  def ln_sf(*args)
    FileUtils.ln_sf(self, *args)
  end

  # FileUtils.cp
  def cp(*args)
    FileUtils.cp(self, *args)
  end

  # FileUtils.cp_r
  def cp_r(*args)
    FileUtils.cp_r(self, *args)
  end

  # FileUtils.mv
  def mv(*args)
    FileUtils.mv(self, *args)
  end

   # FileUtils.rm
  def rm(*args)
    FileUtils.rm(self, *args)
  end

  alias remove rm

  # FileUtils.rm_f
  def rm_f(*args)
    FileUtils.rm_f(self, *args)
  end

  # FileUtils.rm_r
  def rm_r(*args)
    FileUtils.rm_r(self, *args)
  end

  # FileUtils.rm_rf
  def rm_rf(*args)
    FileUtils.rm_rf(self, *args)
  end

  # FileUtils.rmtree
  def rmtree(*args)
    FileUtils.rmtree(self, *args)
  end

  # FileUtils.install
  def install(*args)
    FileUtils.install(self, *args)
  end

  # FileUtils.touch
  def touch(*args)
    FileUtils.touch(*args)
  end

  # FileUtils.compare_file
  def compare_file(file)
    FileUtils.compare_file(self, file)
  end

  # FileUtils.uptodate?
  def uptodate?(*args)
    FileUtils.uptodate(self, *args)
  end

  # FileUtils.copy_file
  def copy_file(*args)
    FileUtils.copy_file(self, *args)
  end

  # FileUtils.remove_dir
  def remove_dir(*args)
    FileUtils.remove_dir(self, *args)
  end

  # FileUtils.remove_file
  def remove_file(*args)
    FileUtils.remove_dir(self, *args)
  end

  # FileUtils.copy_entry
  def copy_entry(*args)
    FileUtils.copy_entry(self, *args)
  end
end

module Kernel
  # Usage: pn{ path }
  #
  # A shortcut for Pathname.new
  #
  def pn
    instance_eval{ Pathname.new(yield) }
  end

  begin
    remove_method(:Pathname)
  rescue NoMethodError, NameError
    # Do nothing, not defined.
  end

  # Synonym for Pathname.new
  #
  def Pathname(path)
    Pathname.new(path)
  end
end

class String
  # Convert a string directly into a Pathname object.
  def to_path
    Pathname.new(self)
  end
end
