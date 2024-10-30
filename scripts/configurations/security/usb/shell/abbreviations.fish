# USBguard abbreviations.
abbr usbga "sudo usbguard list-devices | grep -E '^[0-9]+: block' | awk '{print $1}' | sed 's/://g' | xargs -I{} sudo usbguard allow-device {}"
abbr usbgap "sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf >/dev/null && sudo chmod 0600 /etc/usbguard/rules.conf && sudo chown root:root /etc/usbguard/rules.conf && sudo systemctl restart usbguard"
