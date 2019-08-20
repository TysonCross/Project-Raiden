function output = getStrokeIndices(imds)
    output = indexLabel(imds,double(Label.stroke), 'logical');
end
