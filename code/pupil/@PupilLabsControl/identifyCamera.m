function identifyCamera(obj)

vidCommand = 'ffmpeg -f avfoundation -list_devices true -i ""';
system(vidCommand,'-echo');
idx = GetWithDefault('Which camera index to use','1');
obj.cameraIdx = sprintf('"%d"',idx);

end