a=imread ("./lena.bmp");
a= uint8(rgb2gray(a));
b = uint8(zeros (256,256));

res1=uint8(zeros(256,256));
res2=uint8(zeros(256,256));
cnt=1;

c=1;

for j = 2:256
	for i = 2:256

		dh = double(b(j,i-1))+c - double(a(j,i));
		dv = double(b(j-1,i))+c - double(a(j,i));

		
		if (hv==1 && abs(dh) < abs(dv)-10) 
			hv=0;
		elseif (hv==0 && abs(dh) > abs(dv)+10) 		
			hv=1; 
		endif

		if (c>0) res1(j,i)=255; else res1(j,i)=0; endif
		res2(j,i)=hv*255;
		cnt++;

		if (hv==0)
			d=dh;
			b(j,i) = b(j,i-1)+c;		
		else
			d=dv;
			b(j,i) = b(j-1,i)+c;		
		endif
		
		if (d * c > 0) 
			c=-c;
			if (abs(c)>=4) c=c/4; endif
		else 
			#if (abs(c)<=64) 
			c=c*2; 
			#endif
		endif
		
	endfor
endfor
imshow (b);

	
