import java.nio.IntBuffer;

IntBuffer envMapTextureID;
PShader shader;
PShader shaderOne;
PShader shaderTwo;
PShader shaderThree;
PImage noise;
PImage cubeMap;

int sha = 0;
float forw = 0.0;
float sid = 0.0;
boolean cam = false;

void keyPressed() {
  if (key == '1') 
  {
    
    sha = 1;
    println( "Shader number = " + sha );
    
  } 
  else if (key == '2') 
  {
      sha = 2;
      println( "Shader number = " + sha );
      
  } 
  
  else if (key == '3') 
  {
      sha = 3;
      println( "Shader number = " + sha );
      
  }
  
  else if (key == '4') 
  {
      sha = 4;
      println( "Shader number = " + sha );
      
  }
  
  if( cam == false )
  {
  
    if( key == 'c' || key == 'C' )
    {
    
      cam = true;
      println( "Cam = " + cam );
    
    }
  
  }
  
  else if( cam == true )
  {
  
    if( key == 'c' || key == 'C' )
    {
    
      cam = false;
      println( "Cam = " + cam );
    
    }
  
  }
  
  if( key == CODED )
  {
    
    if( keyCode == UP )
    {
    
      forw -= 0.5;
      println( forw );
    
    }
    
  }
  
  if( key == CODED )
  {
    
    if( keyCode == DOWN )
    {
    
      forw += 0.5;
      println( forw );
    
    }
    
  }  
  
  if( key == CODED )
  {
    
    if( keyCode == RIGHT )
    {
    
      sid += 0.05;
      println( sid );
    
    }
    
  }

  if( key == CODED )
  {
    
    if( keyCode == LEFT )
    {
    
      sid -= 0.05;
      println( sid );
    
    }
    
  }  
    
}

void setup() {
  size(800, 450, P3D);
  noStroke();
  
  noise = loadImage("Noise.png");
  textureWrap(Texture.REPEAT);
  
  cubeMap = loadImage("cubeMapOne.png");
  
  //shader = loadShader("SDFOne.glsl");  
  shader = loadShader("SDF.glsl");
  shaderOne = loadShader("RayMarching.glsl");
  shaderTwo = loadShader("RayMarchingOne.glsl");
  shaderThree = loadShader("Volumetrics.glsl");

}

void draw() {
  
  shader.set("iChannel0", noise);
  shader.set("iResolution", float(width), float(height));
  shader.set("iMouse", float(mouseX), float(mouseY));
  shader.set("iTime", millis() / 1000.0);
  shader.set("iForward", forw);
  shader.set("iSide", sid);
  
  shaderOne.set("iResolution", float(width), float(height));
  shaderOne.set("iMouse", float(mouseX), float(mouseY));
  shaderOne.set("iTime", millis() / 1000.0);
  shaderOne.set("iCam", cam);
  generateCubeMap();
  shaderOne.set("iChannel0", 1);
  shader.set("iForward", forw);
  shader.set("iSide", sid);
  
  shaderTwo.set("iResolution", float(width), float(height));
  shaderTwo.set("iMouse", float(mouseX), float(mouseY));
  shaderTwo.set("iTime", millis() / 1000.0);
  generateCubeMap();
  shaderTwo.set("iChannel0", 1);
  
  shaderThree.set("iChannel0", noise);
  shaderThree.set("iResolution", float(width), float(height));
  shaderThree.set("iMouse", float(mouseX), float(mouseY));
  shaderThree.set("iTime", millis() / 1000.0);
  
  shader(shader);

  if( sha == 2 )
  {
  
    resetShader();
    shader(shaderOne);
    
  }
  
  else if( sha == 3 )
  {
  
    resetShader();
    shader(shaderTwo);
    
  }
  
  else if( sha == 4 )
  {
  
    resetShader();
    shader(shaderThree);
    
  }  
  
  rect(0, 0, width, height);
  
  //println( frameRate );
}

void texturedCube(PImage tex) {
  beginShape(QUADS);
  texture(tex);

  // +Z "front" face

  vertex(-1, -1, 1, 1024, 1024);
  vertex( 1, -1, 1, 2048, 1024);
  vertex( 1, 1, 1, 2048, 2045);
  vertex(-1, 1, 1, 1024, 2045);

  // -Z "back" face
  vertex( 1, -1, -1, 3072, 1024);
  vertex(-1, -1, -1, 4095, 1024);
  vertex(-1, 1, -1, 4095, 2045);
  vertex( 1, 1, -1, 3072, 2045);

  // +Y "bottom" face
  vertex(-1, 1, 1, 1026, 2048);
  vertex( 1, 1, 1, 2044, 2048);
  vertex( 1, 1, -1, 2044, 3072);
  vertex(-1, 1, -1, 1026, 3072);

  // -Y "top" face
  vertex(-1, -1, -1, 1026, 0);
  vertex( 1, -1, -1, 2046, 0);
  vertex( 1, -1, 1, 2046, 1024);
  vertex(-1, -1, 1, 1026, 1024);

  // +X "right" face
  vertex( 1, -1, 1, 2048, 1024);
  vertex( 1, -1, -1, 3072, 1024 );
  vertex( 1, 1, -1, 3072, 2045);
  vertex( 1, 1, 1, 2048, 2045);

  // -X "left" face
  vertex(-1, -1, -1, 1, 1026);
  vertex(-1, -1, 1, 1024, 1026);
  vertex(-1, 1, 1, 1024, 2045);
  vertex(-1, 1, -1, 1, 2045);

  endShape();
}

void generateCubeMap(){
   PGL pgl = beginPGL();
  // create the OpenGL cubeMap
  envMapTextureID = IntBuffer.allocate(1);
  pgl.genTextures(1, envMapTextureID);
  pgl.activeTexture(PGL.TEXTURE1);
  pgl.enable(PGL.TEXTURE_CUBE_MAP);
  pgl.bindTexture(PGL.TEXTURE_CUBE_MAP, envMapTextureID.get(0));
  

  String[] textureNames = { 
    "cubeMapOne.png", "cubeMapOne.png", "cubeMapOne.png", "cubeMapOne.png", "cubeMapOne.png", "cubeMapOne.png"
  };
  PImage[] textures = new PImage[textureNames.length];
  for (int i=0; i<textures.length; i++) {
    textures[i] = loadImage(textureNames[i]);
  }

  // put the textures in the cubeMap
  for (int i=0; i<textures.length; i++) {
    int w = textures[i].width;
    int h = textures[i].height;
    textures[i].loadPixels();
    int[] pix = textures[i].pixels;
    int[] rgbaPixels = new int[pix.length];
    for (int j = 0; j< pix.length; j++) {
      int pixel = pix[j];
      rgbaPixels[j] = 0xFF000000 | ((pixel & 0xFF) << 16) | ((pixel & 0xFF0000) >> 16) | (pixel & 0x0000FF00);
    }
    pgl.texImage2D(PGL.TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, PGL.RGBA, w, h, 0, PGL.RGBA, PGL.UNSIGNED_BYTE, java.nio.IntBuffer.wrap(rgbaPixels));
  }
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_WRAP_S, PGL.CLAMP_TO_EDGE);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_WRAP_T, PGL.CLAMP_TO_EDGE);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_WRAP_R, PGL.CLAMP_TO_EDGE);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_MIN_FILTER, PGL.LINEAR);
  pgl.texParameteri(PGL.TEXTURE_CUBE_MAP, PGL.TEXTURE_MAG_FILTER, PGL.LINEAR);
  endPGL();
}
