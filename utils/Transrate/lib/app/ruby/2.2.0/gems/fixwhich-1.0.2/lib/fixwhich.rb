begin
  require 'rubygems'
rescue LoadError => e
end

require 'pathname2'

#
# Skeleton module for the 'which' routine.
#
# Ideally, one would do this in their code to import the "which" call
# directly into their current namespace:
#
#     require 'which'
#     include Which
#     # do something with which()
#
#
# It is recommended that you look at the documentation for the which()
# call directly for specific usage.
#
#--
#
# The compilation of software known as which.rb is distributed under the
# following terms:
# Copyright (C) 2005-2006 Erik Hollensbe. All rights reserved.
#
# Redistribution and use in source form, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#++

module Which

  #
  # Searches the path, or a provided path with given separators
  # (path_sep, commonly ":") and a separator for directories (dir_sep,
  # commonly "/" or "\\" on windows), will return all of the places
  # that filename occurs. `filename' is included as a part of the
  # output.
  #
  # Note that the filename must both exist in the path _and_ be
  # executable for it to appear in the return value.
  #
  # Those familiar with the which(1) utility from UNIX will notice the
  # similarities.
  #

  def which(filename, path=ENV["PATH"], path_sep=File::PATH_SEPARATOR, dir_sep=File::SEPARATOR)
    dirs = path.split(/#{path_sep}/)

    locations = []

    dirs.each do |dir|
      newfile = "#{dir}#{dir_sep}#{filename}"
      # strip any extra dir separators
      newfile.gsub!(/#{dir_sep}{2,}/, "#{dir_sep}")
      p = Pathname.new(newfile)
      if p.exist? and p.executable?
        locations.push(newfile)
      end
    end

    return locations
  end

  module_function :which
end
