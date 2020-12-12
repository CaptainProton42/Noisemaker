extends Node

# Utility function for HTML5 compatibility.
func save_png(img, fname):
    if (OS.get_name() == "HTML5"):
        # Save a temp file and load it again to get rid of metadata.
        img.save_png("user://temp.png")
        var tempfile = File.new()
        tempfile.open("user://temp.png", File.READ)
        var data = tempfile.get_buffer(tempfile.get_len())

        # Trigger a download.
        var eval_string = """
        function download(filename, img) {
            var element = document.createElement('a');
            element.setAttribute('href', 'data:image/png;base64,' + img);
            element.setAttribute('download', filename);
        
            element.style.display = 'none';
            document.body.appendChild(element);
        
            element.click();
        
            document.body.removeChild(element);
        }

        download("{fname}","{data}");
        """.format({"fname" : fname, "data" : Marshalls.raw_to_base64(data)})
        JavaScript.eval(eval_string)
    else:
        # Just use Godot's internal image save.
        img.save_png(Settings.get_save_dir() + "/" + fname)