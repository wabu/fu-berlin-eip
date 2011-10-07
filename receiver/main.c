/**
 * @file
 * 
 * this is a simple gl/glut video renderer,
 * which is used to decode and output the video stream
 * received over network by the xmos chip
 */

#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>

#include <arpa/inet.h>

#include <GL/glut.h>

#include <config.h>

#define CMPR3_PHASE_FETCH   0
#define CMPR3_PHASE_CS      1
#define CMPR3_PHASE_DIR     2

#include <codec.h>

unsigned int w,h;
unsigned int size;
unsigned char *data;
int texture[1];

void updateTexture() {
    printf("updateing texture %x->%x\n", data, texture[0]);
    
        glTexCoord2f(0.0,1.0);

    glTexImage2D(GL_TEXTURE_2D, 0, 3,
     w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
            glutPostRedisplay();
}

void setPixel(int x, int y, char val) {
    for (int c=0; c<3; c++) {
        data[(y*w+x)*3+c] = val;
    }
}
void setLine(int y, unsigned char *c, int s) {
    for (int x=0; x<s; x++) {
        setPixel(x, y, *(c++));
    }
}

int sock;
unsigned short raw_seq, cmpr_seq = 0, cmpr_next = 0;
unsigned char buff[3000];
unsigned char escFlag = 0;
unsigned char in;
int synced = 0;
cmpr p;
cmpr3 p3;
unsigned char cmpr3_phase = CMPR3_PHASE_FETCH;

int cmpr_x=0, cmpr_y=0;

void decompress(unsigned char *buf, int size) {
    while (size>0) {
        if (escFlag) {
            //printf("processing encflag\n");
            in = CMPR_ESCAPE;
            escFlag = 0;
        } else {
            in = *buf;
            buf++; size--;
        }
        if (in == CMPR_ESCAPE) {
            if (size == 0) { 
                escFlag = 1; break; 
                //printf("setting encflag\n");
            }
            switch (*buf) {
            case CMPR_NEW_FRAME:
                synced = 1;
                buf++; size--;
                //printf("processing new frame\n");
                cmpr_y=0;
                cmpr_start_frame(&p);
                updateTexture();
                continue;
            case CMPR_NEW_LINE:
                buf++; size--;
                //printf("processing new line\n");
                cmpr_y++;
                cmpr_x=0;
                if (synced)
                    cmpr_start_line(&p);
                continue;
            default:
                in = *buf;
                buf++; size--;
            }
        }
        if (!synced)
            continue;
        //printf("adding %d to decoder remeining %d\n", in, size);
        int raw = cmpr_dec(&p, in);
        for (int i=3; i>=0; i--) {
            //printf("processing pixel (%d,%d)\n", cmpr_x, cmpr_y);
            setPixel(cmpr_x++,cmpr_y, (raw>>i*8)&0xff);
        }
    }
}

int bytecount;
void decompress3(unsigned char* buf, int size) {
    while (size > 0) {
        in = *buf;
        buf++; size--;
        bytecount++;
        // handle escapable symbols
        if (!synced) cmpr3_phase = CMPR3_PHASE_FETCH;
        switch (cmpr3_phase) {
        case CMPR3_PHASE_FETCH:
            switch (in) {
            case CMPR_FRAME_SYNC:
                synced = 1;
            case CMPR_NEW_FRAME:
                //printf("processing new frame\n");
                cmpr_y=0;
                if (synced) {
                    cmpr3_start_frame(&p3, in == CMPR_FRAME_SYNC);
                    updateTexture();
                    printf("frame needed %d bytes\n", bytecount);
                    bytecount = 0;
                }
                break;
            case CMPR_NEW_LINE:
                //printf("processing new line\n");
                cmpr_y++;
                cmpr_x=0;
                if (synced) {
                    cmpr3_start_line(&p3);
                    cmpr3_phase = CMPR3_PHASE_CS;
                }
                break;
            default: 
                printf("WARN %x\n", in);
                break;
            }
            break;
        case CMPR3_PHASE_CS:
            //printf("INFO cs [%x]\n",in);
            if( !cmpr3_dec_push_cs(&p3, in) ) 
                cmpr3_phase = CMPR3_PHASE_DIR;
            break;
        case CMPR3_PHASE_DIR:
            //printf("INFO dir [%x => %d]\n",in, p3.dir_cnt);
            if( !cmpr3_dec_push_dir(&p3, in)) {
                while (p3.x < p3.w) {
                    int raw = cmpr3_dec_pull(&p3);
                    for (int i=3; i>=0; i--) {
                        //printf("processing pixel (%d,%d)\n", cmpr_x, cmpr_y);
                        setPixel(cmpr_x++,cmpr_y, (raw>>i*8)&0xff);
                    }
                }
                cmpr3_phase = CMPR3_PHASE_FETCH;
            }
            break;
        default: break;
        }
    }
}

unsigned char type, raw_line;

void receiver() {

    int size;
    while ((size = recv(sock, buff, sizeof(buff), MSG_DONTWAIT)) > 0) {
        //printf("recved %d\n", size);
        if (buff[0] != type) {
            synced = 0;
        }
        type = buff[0];

        switch (type) {
        case 1: // raw
            raw_seq = buff[1] << 8 | buff[2];
            raw_line = buff[3];
            setLine(raw_line, buff+6, size-6);
            if (raw_line == h-1) {
                updateTexture();
            }
            break;
        case 2: // cmpr
        case 3: // cmpr3
            cmpr_seq = buff[1] << 8 | buff[2];
            if (cmpr_seq != cmpr_next) {
                synced = 0;
                printf("packet lost %d -> %d\n", (int)cmpr_next, (int)cmpr_seq);
            }
            cmpr_next = cmpr_seq+1;
            //printf("received compression unit %d\n", cmpr_seq);
            if (type == 2)
                decompress(buff+3, size-3);
            else
                decompress3(buff+3, size-3);
            break;
        default:
            break;
        }

        // XXX do on end of frame
    }
}

void init_udp(int port) {
    struct sockaddr_in addr;

    sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = port;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    bind(sock, (struct sockaddr*)&addr, sizeof(addr));

    cmpr_init(&p, VID_WIDTH, VID_HEIGHT);
    cmpr3_init(&p3, VID_WIDTH, VID_HEIGHT, 4);

    printf("udp init done\n");
}

void display(void){
    glClear(GL_COLOR_BUFFER_BIT);
        glBegin(GL_POLYGON);
        glTexCoord2f(0.0f, 1.0f);
        glVertex2f(-1, -1);
        glTexCoord2f(0.0f, 0.0f);
        glVertex2f(-1, 1);
        glTexCoord2f(1.0f, 0.0f);
        glVertex2f(1, 1);
        glTexCoord2f(1.0f, 1.0f);
        glVertex2f(1, -1);
    glEnd();

    glFlush(); 
    glutSwapBuffers();
}

void init_gl(){
    glEnable(GL_TEXTURE_2D);
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
    w=160; h=120;

    glutInit(&argc,argv); 
    glutInitDisplayMode (GLUT_DOUBLE | GLUT_RGB);
    glutCreateWindow("simple");
    glutDisplayFunc(display);
    glutIdleFunc(receiver);

    init_gl();
    init_udp(htons(12345));

    glutMainLoop();

    return 0;
}

