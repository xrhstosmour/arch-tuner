# Base function to copy files and directories using `xcp` instead of `cp`.
# Usage:
#   cp_to_xcp source destination -> xcp source destination
#   cp_to_xcp -R source destination -> xcp --recursive source destination
function cp_to_xcp
    if contains '-R' $argv
        set args (string replace -a '-R' '--recursive' $argv)
        xcp $args
    else
        xcp $argv
    end
end
