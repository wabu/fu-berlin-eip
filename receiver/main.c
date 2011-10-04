/*
 *  This program draws a white rectangle on a black background.
 */

#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <GL/glut.h>

unsigned int w,h;
unsigned int size;
unsigned char *data;
int texture[1];

void updateTexture() {
        glTexCoord2f(0.0,1.0);

	glTexImage2D(GL_TEXTURE_2D, 0, 3,
	 w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, texture);
}

void setPixel(int x, int y, char val) {
	for (int c=0; c<3; c++) {
		data[(y*w+x)*3+c] = val;
	}
}

int sock;
char buff[3000];

void receiver() {
	recv(sock, buff, sizeof(buff), 0);

	// TODO:
	// parse buffer
	// use something line setPixel
	// when frame finished, updateTexture and call glutPostRedisplay()
}

void init_udp(int port) {
	struct sockaddr_in addr;

	sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = port;
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	bind(sock, (struct sockaddr*)&addr, sizeof(addr));
}

void display(void){
        glClear(GL_COLOR_BUFFER_BIT);
        glBegin(GL_POLYGON);
		glTexCoord2f(0.0f, 0.0f);
                glVertex2f(-1, -1);
		glTexCoord2f(0.0f, 1.0f);
                glVertex2f(-1, 1);
		glTexCoord2f(1.0f, 1.0f);
                glVertex2f(1, 1);
		glTexCoord2f(1.0f, 0.0f);
                glVertex2f(1, -1);
        glEnd();

        glFlush(); 
        glutSwapBuffers();
}

void init_gl(){
	glClearColor (0.0, 0.0, 0.0, 0.0);
	glColor3f(0.5, 0.5, 0.5);

        glMatrixMode (GL_PROJECTION);
        glLoadIdentity ();
        glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0); 

        glGenTextures(1, (GLuint*)texture);
        glBindTexture(GL_TEXTURE_2D, texture[0]);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);

	size = w*h*3;
	data = malloc(size);
}

int main(int argc, char** argv){
        glutInit(&argc,argv); 
        glutInitDisplayMode (GLUT_DOUBLE | GLUT_RGB);
        glutCreateWindow("simple");
        glutDisplayFunc(display);
	glutIdleFunc(receiver);

        init_gl();
	init_udp(12345);

        glutMainLoop();

        return 0;
}

