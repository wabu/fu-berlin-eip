a=imread ("./lena.bmp");
a= uint8(rgb2gray(a));
%a=imread ('./chess.64.bmp');

dim=256;

b = uint8(zeros (dim,dim));

res1=uint8(zeros(dim,dim));
res2=uint8(zeros(dim,dim));


cs=zeros(dim,dim);

c=1;
hv=0;

cnt=0;

for j = 2:dim
	for i = 2:dim

		ch = cs(j,i-1);
		dh = double(b(j,i-1))+ch - double(a(j,i));
		cv = cs(j-1,i);
		dv = double(b(j-1,i))+cv - double(a(j,i));

		
		if (hv==1 && abs(dh) < abs(dv)-10) 
			hv=0;
			cnt++;
		elseif (hv==0 && abs(dh) > abs(dv)+10) 		
			hv=1; 
			cnt++;
		endif
		
		
		if (c>0) res1(j,i)=255; else res1(j,i)=0; endif
		res2(j,i)=hv*255;

		if (hv==0)
			d=dh;
			c=ch;
			b(j,i) = b(j,i-1)+c;		
		else
			d=dv;
			c=cv;
			b(j,i) = b(j-1,i)+c;		
		endif
		
		if (c==0) c=1; endif
	
		if (d * c > 0) 
			c=-c;
			if (abs(c)>=2) c=c/2; endif
		else 
			#if (abs(c)<=64) 
			c=c+c/2; 
			#endif
		endif
		
		cs(j,i)=c;
		
	endfor
endfor
cnt
imshow (b);

	
