a=imread ('./hgrad.inv.64.bmp');
% a= uint8(rgb2gray(a));
[rows, cols] = size(a);
b = uint8(zeros (rows,cols));

res1=uint8(zeros(rows,cols));
res2=uint8(zeros(rows,cols));
cnt=1;

c=1;
lastc =1;
lastlastc =1;
for j = 2:rows
	for i = 2:cols

		dh = double(b(j,i-1))+c - double(a(j,i));
		dv = double(b(j-1,i))+c - double(a(j,i));

		if (hv==1 && abs(dh) < abs(dv)-10) 
			hv=0;
		elseif (hv==0 && abs(dh) > abs(dv)+10) 		
			hv=1; 
		endif
		

                res1(j,i) = c;
		res2(j,i)=hv*255;
		cnt++;

		if (hv==0)
			d=dh;
			b(j,i) = b(j,i-1)+c;		
		else
			d=dv;
			b(j,i) = b(j-1,i)+c;		
		endif
		
		lastlastc=lastc;
		lastc=c;
		if (d * c > 0) c=-c; endif 

		if (c*lastc>0 && lastlastc*lastc>0 && c<128) c=c*2;
		elseif (c*lastc<0 && abs(c)>1) c = c/2; endif;

		
		
	endfor
endfor
imshow (b);

	
