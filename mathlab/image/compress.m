a=imread ("./lena.bmp");
a= uint8(rgb2gray(a));
b = uint8(zeros (256,256));
for j = 2:256
	c=1;
	lastc =1;
	lastlastc =1;
	for i = 2:256

		dh = double(b(j,i-1)) - double(a(j,i));
		dv = double(b(j-1,i)) - double(a(j,i));

		if (abs(dh) < abs(dv)) 
			hv=0;
			d=dh;
		else 
			hv=1; 
			d=dv;
		endif
		
		lastlastc=lastc;
		lastc=c;
		if (d * c > 0) c=-c; endif 

#		if (c*lastc>0 && lastlastc*lastc>0 && c<64) c=c*2;
#		elseif (c*lastc<0 && abs(c)>1) c=c/2; endif;

		if (hv==0)
			b(j,i) = b(j,i-1)+c;		
		else
			b(j,i) = b(j-1,i)+c;		
		endif
		
	endfor
endfor
imshow (b);

	
