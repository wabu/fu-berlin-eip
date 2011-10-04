a=imread ("c:\\user\\hamid\\image\\test_field.bmp");

b=rgb2hsv(a);
d=uint8(zeros(480,640,3));

color=0.95;
colwidth=0.05;
sat = 0.2;
satwidth = 0.9;

for j = 1:480
	for i = 1:640
		#if((b(j,i,1) < color + colwidth) && (b(j,i,1) > color - colwidth) && (b(j,i,2) < sat + satwidth) && (b(j,i,2) > sat - satwidth)) 
		if (b(j,i,3) > 0.4 && b(j,i,2) < 0.15)
			d(j,i,:)=a(j,i,:);
		endif
	endfor
endfor

imshow(d)