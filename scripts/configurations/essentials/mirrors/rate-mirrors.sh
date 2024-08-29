rate-mirrors --disable-comments-in-file --save mirrors.txt arch && cat mirrors.txt | head -n 5 | sudo tee /etc/pacman.d/mirrorlist && sudo rm mirrors.txt
