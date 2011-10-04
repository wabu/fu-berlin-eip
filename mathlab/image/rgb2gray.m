function gray = rgb2gray (rgb)

  if (nargin != 1)
    print_usage();
  endif

  if (ismatrix (rgb) && ndims(rgb) == 2 && columns(rgb) == 3)
    ntscmap = rgb2ntsc (rgb);
    gray = ntscmap (:, 1) * ones (1, 3);
  elseif (ismatrix(rgb) && ndims(rgb) == 3)
    switch(class(rgb))
    case "double"
      gray = mean(rgb,3);
    case "uint8"
      gray = uint8(mean(rgb,3));
    case "uint16"
      gray = uint16(mean(rgb,3));
    otherwise
      error("rgb2gray: unsupported class %s", class(rgb));
    endswitch
  else
    error("rgb2gray: the input must either be an RGB image or a color map");
  endif
endfunction
