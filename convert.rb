layout = RBA::Layout.new
options = RBA::SaveLayoutOptions.new
layout.read($input)
options.gds2_multi_xy_records = true
layout.write($output,options)