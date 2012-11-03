//
//  IAOaobenchGLSL.m
//  iaobenchCollection
//
//  Created by Satoru NAKAJIMA on 2012/10/07.
//  Copyright (c) 2012年 Satoru NAKAJIMA. All rights reserved.
//

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

#import "IAOaobenchGLSL.h"

#define ATTRID_position 0

@interface IAOaobenchGLSL ()
{
	EAGLContext *glcontext;
	GLuint textureName;
	GLuint frameBufferName;
	GLuint shaderProgram;
	
	//GLuint attrid_position;
	GLuint uniformPos_resolution;
}
@end

// Objective-C interface
@implementation IAOaobenchGLSL

- (void)setupGLContextWidth:(int)w height:(int)h {
	if(glcontext) {
		[EAGLContext setCurrentContext:glcontext];
		return;
	}
	
	glcontext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	[EAGLContext setCurrentContext:glcontext];
	
	glGenTextures(1, &textureName);
	glBindTexture(GL_TEXTURE_2D, textureName);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	//NSLog(@"init texture:0x%04x", glGetError());
	
	glGenFramebuffers(1, &frameBufferName);
	glBindFramebuffer(GL_FRAMEBUFFER, frameBufferName);
	
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureName, 0);
	//NSLog(@"init framebuffer:0x%04x", glGetError());
	
	GLuint renderbuf;
	glGenRenderbuffers(1, &renderbuf);
	glBindRenderbuffer(GL_RENDERBUFFER, renderbuf);
	//NSLog(@"gen renderbuffer:0x%04x", glGetError());
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, w, h);
	//NSLog(@"storage renderbuffer:0x%04x", glGetError());
	
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, renderbuf);
	//NSLog(@"set renderbuffer:0x%04x", glGetError());
	
	GLenum glerr = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if(glerr != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"framebuffer not completed: 0x%04x", glerr);
	}
}

- (void)setupProgram {
	GLint stat;
	GLint loglen;
	
	if(shaderProgram) {
		return;
	}
	
	shaderProgram = 0;
	
	NSBundle *mb = [NSBundle mainBundle];
	NSString *vtxshPath = [mb pathForResource:@"ao_glsl.vsh" ofType:nil];
	NSString *frgshPath = [mb pathForResource:@"ao_glsl.fsh" ofType:nil];
	
	const char *vtxshSrc = [[NSString stringWithContentsOfFile:vtxshPath encoding:NSUTF8StringEncoding error:nil] UTF8String];
	const char *frgshSrc = [[NSString stringWithContentsOfFile:frgshPath encoding:NSUTF8StringEncoding error:nil] UTF8String];
	
	GLuint shaders[2];
	for(int i = 0; i < 2; i++) {
		const char *srcs[] = {vtxshSrc, frgshSrc};
		GLenum types[] = {GL_VERTEX_SHADER, GL_FRAGMENT_SHADER};
		
		shaders[i] = glCreateShader(types[i]);
		glShaderSource(shaders[i], 1, &srcs[i], NULL);
		glCompileShader(shaders[i]);
		
		loglen = 0;
		glGetShaderiv(shaders[i], GL_INFO_LOG_LENGTH, &loglen);
		if(loglen > 0) {
			char *logstr = (char*)malloc(loglen + 1);
			glGetShaderInfoLog(shaders[i], loglen, &loglen, logstr);
			NSLog(@"shader[%d] compile error: %s", i, logstr);
			free(logstr);
		}
		
		stat = 0;
		glGetShaderiv(shaders[i], GL_COMPILE_STATUS, &stat);
		if(stat == 0) {
			NSLog(@"shader[%d] state: 0x%04x", i, stat);
			glDeleteShader(shaders[i]);
			shaders[i] = 0;
		}
	}
	
	shaderProgram = glCreateProgram();
	glAttachShader(shaderProgram, shaders[0]);
	glAttachShader(shaderProgram, shaders[1]);
	glLinkProgram(shaderProgram);
	
	loglen = 0;
	glGetProgramiv(shaderProgram, GL_INFO_LOG_LENGTH, &loglen);
	if(loglen > 0) {
		char *logstr = (char*)malloc(loglen + 1);
		glGetProgramInfoLog(shaderProgram, loglen, &loglen, logstr);
		NSLog(@"shader link error: %s", logstr);
		free(logstr);
	}
	
	for(int i = 0; i < 2; i++) {
		glDetachShader(shaderProgram, shaders[i]);
		glDeleteShader(shaders[i]);
	}
	
	stat = 0;
	glGetProgramiv(shaderProgram, GL_LINK_STATUS, &stat);
	if(stat == 0) {
		NSLog(@"link state: %d", stat);
		glDeleteProgram(shaderProgram);
		shaderProgram = 0;
		return;
	}
	
	glBindAttribLocation(shaderProgram, ATTRID_position, "position");
	uniformPos_resolution = glGetUniformLocation(shaderProgram, "resolution");
}

- (void)tearDownGL {
	if(glcontext) {
		[EAGLContext setCurrentContext:glcontext];
		
		glDeleteFramebuffers(1, &frameBufferName);
		frameBufferName = 0;
		glDeleteTextures(1, &textureName);
		textureName = 0;
	}
	
	if(shaderProgram) {
		glDeleteProgram(shaderProgram);
		shaderProgram = 0;
	}
	
	if([EAGLContext currentContext] == glcontext) {
		[EAGLContext setCurrentContext:nil];
	}
	glcontext = nil;
}

/////
- (void)dealloc {
	[self tearDownGL];
}

#pragma mark - IAORenderer
- (NSString*)name {
	return @"aobench offline GLSL";
}

- (NSString*)information {
	return @"Offline GLSL. setup OpenGL every time.";
}

- (IAORendererType)rendererType {
	return kIAORendererTypeOffline;
}

- (NSTimeInterval)render:(unsigned char*)buffer width:(int)w height:(int)h {
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	
	[self setupGLContextWidth:w height:h];
	[self setupProgram];
	
	GLfloat verts[] = {
		-1.0, -1.0,
		-1.0,  1.0,
		 1.0, -1.0,
		 1.0,  1.0
	};
	
	glBindFramebuffer(GL_FRAMEBUFFER, frameBufferName);
	glViewport(0, 0, w, h);
	
	glDisable(GL_DEPTH_TEST);
	
	glUseProgram(shaderProgram);
	
	glUniform2f(uniformPos_resolution, (GLfloat)w, (GLfloat)h);
	
	glVertexAttribPointer(ATTRID_position, 2, GL_FLOAT, 0, 0, verts);
	glEnableVertexAttribArray(ATTRID_position);
	
	/*
	{
		glValidateProgram(shaderProgram);
		GLint loglen = 0;
		glGetProgramiv(shaderProgram, GL_INFO_LOG_LENGTH, &loglen);
		if(loglen > 0) {
			char *logstr = (char*)malloc(loglen + 1);
			glGetProgramInfoLog(shaderProgram, loglen, &loglen, logstr);
			NSLog(@"shader validate error: %s", logstr);
			free(logstr);
		}
		GLint stat = 0;
		glGetProgramiv(shaderProgram, GL_VALIDATE_STATUS, &stat);
		if(stat == 0) {
			NSLog(@"validate state: %d", stat);
			glDeleteProgram(shaderProgram);
			shaderProgram = 0;
		}
	}
	*/
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	glFinish();
	
	glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	
	[self tearDownGL];
	
	return [NSDate timeIntervalSinceReferenceDate] - startTime;
}

@end
