# Function to process a single duplicate group.
# Usage:
#   process_group "file1" "file2" "file3"
function process_group
    set files $argv
    set best ""
    set best_size -1
    set best_pri 1000
    set best_mod -1

    for file in $files
        # Get file size.
        set size (stat -c %s $file 2>/dev/null ^/dev/null; or stat -f %z $file 2>/dev/null ^/dev/null)
        if test -z "$size"
            continue
        end

        # Get last modification time.
        set mod (stat -c %Y $file 2>/dev/null ^/dev/null; or stat -f %m $file 2>/dev/null ^/dev/null)

        # Get file extension (lowercased).
        set ext (string lower (string split -r '.' $file)[-1])

        # Assign priority based on file type.
        switch $ext
            case jpg jpeg
                set pri 1
            case png
                set pri 2
            case webp
                set pri 3
            case gif
                set pri 4
            case bmp
                set pri 5
            case tiff tif
                set pri 6
            case heic heif
                set pri 7
            case raw
                set pri 8
            case svg
                set pri 9
            case pdf
                set pri 10
            case mp4
                set pri 11
            case mkv
                set pri 12
            case avi
                set pri 13
            case mov
                set pri 14
            case flv
                set pri 15
            case wmv
                set pri 16
            case mpeg
                set pri 17
            case webm
                set pri 18
            case '*'
                set pri 99
        end

        # Select best file based on size > priority > modification time.
        if test $size -gt $best_size
            set best $file
            set best_size $size
            set best_pri $pri
            set best_mod $mod
        else if test $size -eq $best_size
            if test $pri -lt $best_pri
                set best $file
                set best_pri $pri
                set best_mod $mod
            else if test $pri -eq $best_pri -a $mod -gt $best_mod
                set best $file
                set best_mod $mod
            end
        end
    end

    # Print all files except the best.
    for file in $files
        if test "$file" != "$best"
            echo $file
        end
    end
end

# Function to keep the best file per `fdupes` group.
# Usage:
#   keep_best_file
function keep_best_file
    set group

    # Read and group fdupes output.
    fdupes -r . | while read -l line
        if test -z "$line"
            if test (count $group) -gt 0
                process_group $group
                set group
            end
        else
            set group $group $line
        end
    end

    # Process final group if any.
    if test (count $group) -gt 0
        process_group $group
    end
end
