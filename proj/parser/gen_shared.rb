
class GenShared
  class << self

    def export_to_function!(haxe)
      haxe.gsub!(/^export function/, "public function")
      haxe.gsub!(/^function/, "private function")
    end

    def export_type_to_typedef!(haxe)
      # Test this...
      # haxe.gsub!(/export type (.*?) = {.*?\n};/m) { |block|
      #   block.gsub!(/(\w+)\?:(\s+\?)?/, "?\\1 /* opt */ :")
      #   block.sub!(/^export type/, "typedef /* export type */")
      #   block
      # }

      haxe.gsub!(/export type/, "typedef /* export type */")
      haxe.gsub!(/(\w+)\?:(\s+\?)?/, "?\\1 /* opt */ :")
    end

    def backticks!(haxe)
      # Backticks to single ticks
      haxe.gsub!(/\`.*?\`/) { |match|
        cont = match[1,match.length-2];
        cont.gsub!('\'', '\\\\'+"'");
        cont.gsub!('\\\\$', '$'); # recover actual intentional ${ }
        ## cont.gsub!('$', '$$');
        ## cont.gsub!('\\\\$$', '$'); # recover actual intentional ${ }
        "'#{ cont }'"
      }
      #haxe.gsub!(/\`.*?\`/) { |match| cont = match[1,match.length-2]; cont.gsub!("'", "\'"); cont.gsub!('$', '$$'); "'#{ cont }'" }
    end

    def case_fall_throughs! haxe
      # Collapse case fall-throughs
      while haxe.match(/(case \w+\.\w+( \|.*?)?):\s*\n\s*case /m)
        haxe.gsub!(/(case \w+\.\w+( \|.*?)?):\s*\n\s*case /m, "\\1 | /*CFT*/ ")
      end
      while haxe.match(/(case ['"]\w+['"]( \|.*?)?):\s*\n\s*case /m)
        haxe.gsub!(/(case ['"]\w+['"]( \|.*?)?):\s*\n\s*case /m, "\\1 | /*CFT*/ ")
      end
      while haxe.match(/(case \d+( \|.*?)?):\s*\n\s*case /m)
        haxe.gsub!(/(case \d+( \|.*?)?):\s*\n\s*case /m, "\\1 | /*CFT*/ ")
      end

      # remove break; statements just before new case statements
      haxe.gsub!(/break;(.+?)(case|default)/m) { |match|
        obet = $1.dup
        between = $1
        stmt = $2
        if (!between.include?('}')) then
          # ignore comments in between
          between.gsub!(/\/\/.*?$/, "")
          between.gsub!(/\/\*.*?\*\//m, "")
          if (between.match(/^\s+$/)) then
            match = "/* br#{ stmt }eak; */#{ obet }#{ stmt }"
          end
        end
        match
      }
    end

    def basic_types_and_junk!(haxe)
      # Basic types
      haxe.gsub!(/:\s*boolean\b/, ":Bool")
      haxe.gsub!(/:\s*any\b([^(])/, ":Dynamic\\1")
      haxe.gsub!(/:\s*string\b/, ":String")
      haxe.gsub!(/:\s*number\b/, ":Int /* number */")

      # const let ===
      haxe.gsub!(/\bconst\s+/, "var ")
      haxe.gsub!(/\blet\s+/, "var ")
      haxe.gsub!(/===/, "==")
      haxe.gsub!(/!==/, "!=")
    end

    def func_args_trailing_comma!(haxe)
      # Remove newline after last function parameter -- also keeps {
      # on the next line, but that's just stylistic
      haxe.gsub!(/function (\w+\(.*?),\s+\):(.*?){/m, "function \\1):\\2\n{")
    end

    def func_calls_trailing_comma!(haxe)
      # Haxe doesn't like comma, newline, close paren
      haxe.gsub!(/,\s*\n\s*\)\s*/m, ")")
    end

    def ES_implied_object_keys(haxe)

      replace_esiok = lambda { |code|
        # ESIOK...   ES implied object key name... GRR!
        code.gsub!(/{(.*?)}/m) { |block|
          if (block[1,block.length-1].include?('{')) then
            # inmost { } blocks, please
            #puts "================"
            #puts "================"
            #puts "================ THERE:"
            #puts block[1,block.length-1]
            #puts "================ NOW:"
            block ='{' + replace_esiok.call(block[1,block.length-1])
            #puts block
          else
            looks_like_a_struct = true
            #puts "================"
            #puts "================"
            #puts "================ HERE:"
            #puts block
            block[1,block.length-2].split("\n").each { |line|
              if (line.match(/^\s*$/)) then
              elsif (!line.match(/^(\s+)(\w+)\s*.*?,/)) then
                looks_like_a_struct = false if !line.match(/^\s*[?:]/)
                #puts "LLAS failed on: #{ line }"
              end
            }
            #puts "===== LLAS=#{ looks_like_a_struct }"
            if (looks_like_a_struct) then
              block = block.split("\n").map { |line|
                line.sub(/^(\s+)(\w+)\s*,\s*$/, "\\1\\2:\\2, /* ESIOK: stupid inferred key name */")
              }.join("\n")
            end
            #puts "MOD:"
            #puts block
            #puts "================"
            #puts "================"
          end
          block
        }
        code
      }
      return replace_esiok.call(haxe)

    end

  end
end
