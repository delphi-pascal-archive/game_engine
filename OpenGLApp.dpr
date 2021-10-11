// Author: Jan Horn
// Email: jhorn@global.co.za
// Website: http://www.sulaco.co.za, http://home.global.co.za/~jhorn

program OpenGLApp;

uses
  Windows, Messages, OpenGL, SysUtils, Textures;

const
 WND_TITLE='Basic game engine';
 FPS_TIMER=1;                    // Timer to calculate FPS
 FPS_INTERVAL=500;               // Calculate FPS every 1000 ms

type
 TCoord = record
   X, Y, Z : glFLoat;
 end;
 TFace = record
   V1, V2, V3, V4: integer;
   U, V: glFloat;
   TextureIndex: integer;
 end;

var
 h_Wnd: HWND;                       // Global window handle
 h_DC: HDC;                         // Global device context
 h_RC: HGLRC;                       // OpenGL rendering context
 keys: array [0..255] of Boolean;   // Holds keystrokes
 FPSCount: integer = 0;            // Counter for FPS
 ElapsedTime: integer;             // Elapsed time between frames
 FrameTime: integer;
 // Textures
 Texture: array of glUint;
 // User variables
 TextureCount: integer;
 VertexCount: integer;
 FaceCount: integer;
 Vertex: array of TCoord;
 Face: array of TFace;
 X, Z: glFloat;
 HeadMovement, HeadMovAngle: glFloat;
 mpos: TPoint;
 Heading: glFloat;
 Tilt: glFloat;
 //
 MouseSpeed: integer = 7;
 MoveSpeed: glFloat = 0.03;

{$R *.RES}

procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;
// Load the map info from the map.txt files
procedure LoadMap;
var
 F: Textfile;
 Tex: array of string;
 S: string;
 I, J: integer;
begin
 AssignFile(F, 'map.txt');
 Reset(F);
 // Load the textures
 Readln(F, TextureCount);
 SetLength(Tex, TextureCount);
 SetLength(Texture, TextureCount);
 for I:=0 to TextureCount-1 do
  begin
   Readln(F, S);
   Tex[i]:=Copy(S, 1, Pos(' ', S)-1);
   S :=Copy(S, Pos(' ', S)+1, length(S));
   LoadTexture(S, Texture[i], FALSE);
  end;
 // Load the vertices
 Readln(F, VertexCount);
 SetLength(Vertex, VertexCount);
 for I:=0 to VertexCount-1 do
  Readln(F, Vertex[i].X, Vertex[i].Y, Vertex[i].Z);
 // Load the faces
 Readln(F, FaceCount);
 SetLength(Face, FaceCount);
 for I:=0 to FaceCount-1 do
  begin
   Readln(F, Face[i].V1, Face[i].V2, Face[i].V3, Face[i].V4, Face[i].U, Face[i].V, S);
   S:=Trim(Copy(S, 1, 12));
   for J :=0 to TextureCount-1 do
    if Tex[J]=S
    then Face[i].TextureIndex:=J;
  end;
 CloseFile(F);
end;

// Function to draw the actual scene
procedure glDraw();
var
 I: integer;
begin
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // Clear The Screen And The Depth Buffer
 glLoadIdentity();                                       // Reset The View
 glRotate(Tilt, 1, 0, 0);
 glRotate(Heading, 0, 1, 0);
 glTranslatef(X, -0.5 + HeadMovement, Z);
 for I:=0 to FaceCount-1 do
  with face[i] do
   begin
    glBindTexture(GL_TEXTURE_2D, Texture[TextureIndex]);
    glBegin(GL_QUADS);
     glTexCoord(0, 0);  glVertex3fv(@Vertex[V1-1]);
     glTexCoord(U, 0);  glVertex3fv(@Vertex[V2-1]);
     glTexCoord(U, V);  glVertex3fv(@Vertex[V3-1]);
     glTexCoord(0, V);  glVertex3fv(@Vertex[V4-1]);
    glEnd();
  end;
end;

// Initialise OpenGL
procedure glInit();
begin
 glClearColor(0.0, 0.0, 0.0, 0.0); 	 // Black Background
 glShadeModel(GL_SMOOTH);            // Enables Smooth Color Shading
 glClearDepth(1.0);                  // Depth Buffer Setup
 glEnable(GL_DEPTH_TEST);            // Enable Depth Buffer
 glDepthFunc(GL_LESS);		           // The Type Of Depth Test To Do
 glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST); //Realy Nice perspective calculations
 glEnable(GL_TEXTURE_2D);            // Enable Texture Mapping
 LoadMap;
 //
 Heading:=180;
 X:=2.25;
 Z:=2;
end;

// Handle window resize
procedure glResizeWnd(Width, Height : Integer);
begin
 if (Height=0)
 then Height := 1; // prevent divide by zero exception
 glViewport(0, 0, Width, Height);    // Set the viewport for the OpenGL window
 glMatrixMode(GL_PROJECTION);        // Change Matrix Mode to Projection
 glLoadIdentity();                   // Reset View
 gluPerspective(45.0, Width/Height, 0.1, 100.0);  // Do the perspective calculations. Last value = max clipping depth
 glMatrixMode(GL_MODELVIEW);         // Return to the modelview matrix
 glLoadIdentity();                   // Reset View
end;

// Processes all the keystrokes
procedure ProcessKeys;
begin
 if Keys[VK_UP]
 then
  begin
   X:=X-sin(Heading*pi/180)*FrameTime/600;   // FrameTime/600=movement speed
   Z:=Z+cos(Heading*pi/180)*FrameTime/600;   // FrameTime/600=movement speed
   HeadMovAngle:=HeadMovAngle+5;
   HeadMovement:=0.008*sin(HeadMovAngle*pi/180);
  end;
 if Keys[VK_DOWN]
 then
  begin
   X:=X+sin(Heading*pi/180)*FrameTime/600;
   Z:=Z-cos(Heading*pi/180)*FrameTime/600;
   HeadMovAngle:=HeadMovAngle-5;
   HeadMovement:=0.008*sin(HeadMovAngle*pi/180);
  end;
 if Keys[VK_LEFT]
 then
  begin
   X:=X+sin((Heading+90)*pi/180)*FrameTime/900;  // FrameTime/900=movement speed
   Z:=Z-cos((Heading+90)*pi/180)*FrameTime/900;  // straffing = 50% slower
  end;
 if Keys[VK_RIGHT]
 then
  begin
   X:=X-sin((Heading+90)*pi/180)*FrameTime/900;
   Z:=Z+cos((Heading+90)*pi/180)*FrameTime/900;
  end;
 if Keys[VK_RETURN]
 then
  begin
   Loadmap;
   glDraw;
  end;
end;

// Determines the application�s response to the messages received
function WndProc(hWnd: HWND; Msg: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
begin
 case (Msg) of
    WM_CREATE:
      begin
       // Insert stuff you want executed when the program starts
      end;
    WM_CLOSE:
      begin
       PostQuitMessage(0);
       Result:=0
      end;
    WM_KEYDOWN: // Set the pressed key (wparam) to equal true so we can check if its pressed
      begin
       keys[wParam]:=true;
       Result:=0;
      end;
    WM_KEYUP: // Set the released key (wparam) to equal false so we can check if its pressed
      begin
       keys[wParam]:=false;
       Result:=0;
      end;
    WM_SIZE: // Resize the window with the new width and height
      begin
       glResizeWnd(LOWORD(lParam),HIWORD(lParam));
       Result:=0;
      end;
    WM_TIMER: // Add code here for all timers to be used.
      begin
       if wParam=FPS_TIMER
       then
        begin
         FPSCount:=Round(FPSCount*1000/FPS_INTERVAL); // calculate to get per Second incase intercal is less or greater than 1 second
         SetWindowText(h_Wnd, PChar(WND_TITLE+' [ '+intToStr(FPSCount)+' FPS ]'));
         FPSCount:=0;
         Result:=0;
        end;
      end;
    else Result:=DefWindowProc(hWnd, Msg, wParam, lParam); // Default result if nothing happens
  end;
end;

// Properly destroys the window created at startup (no memory leaks)  }
procedure glKillWnd(Fullscreen : Boolean);
begin
 if Fullscreen
 then             // Change back to non fullscreen
  begin
   ChangeDisplaySettings(devmode(nil^), 0);
   ShowCursor(True);
  end;
 // Makes current rendering context not current, and releases the device
 // context that is used by the rendering context.
 if (not wglMakeCurrent(h_DC, 0))
 then MessageBox(0, 'Release of DC and RC failed!', 'Error', MB_OK or MB_ICONERROR);
 // Attempts to delete the rendering context
 if (not wglDeleteContext(h_RC))
 then
  begin
   MessageBox(0, 'Release of rendering context failed!', 'Error', MB_OK or MB_ICONERROR);
   h_RC:=0;
  end;
 // Attemps to release the device context
 if ((h_DC>0) and (ReleaseDC(h_Wnd, h_DC)=0))
 then
  begin
   MessageBox(0, 'Release of device context failed!', 'Error', MB_OK or MB_ICONERROR);
   h_DC:=0;
  end;
 // Attempts to destroy the window
 if ((h_Wnd<>0) and (not DestroyWindow(h_Wnd)))
 then
  begin
   MessageBox(0, 'Unable to destroy window!', 'Error', MB_OK or MB_ICONERROR);
   h_Wnd:=0;
  end;
 // Attempts to unregister the window class
 if (not UnRegisterClass('OpenGL', hInstance))
 then
  begin
   MessageBox(0, 'Unable to unregister window class!', 'Error', MB_OK or MB_ICONERROR);
   hInstance:=0;
  end;
end;

// Creates the window and attaches a OpenGL rendering context to it
function glCreateWnd(Width, Height : Integer; Fullscreen : Boolean; PixelDepth : Integer) : Boolean;
var
 wndClass: TWndClass;         // Window class
 dwStyle: DWORD;              // Window styles
 dwExStyle: DWORD;            // Extended window styles
 dmScreenSettings: DEVMODE;   // Screen settings (fullscreen, etc...)
 PixelFormat: GLuint;         // Settings for the OpenGL rendering
 h_Instance: HINST;           // Current instance
 pfd: TPIXELFORMATDESCRIPTOR;  // Settings for the OpenGL window
begin
 h_Instance:=GetModuleHandle(nil);       //Grab An Instance For Our Window
 ZeroMemory(@wndClass, SizeOf(wndClass));  // Clear the window class structure
 with wndClass do                    // Set up the window class
  begin
   style:=CS_HREDRAW or    // Redraws entire window if length changes
          CS_VREDRAW or    // Redraws entire window if height changes
          CS_OWNDC;        // Unique device context for the window
   lpfnWndProc:=@WndProc;        // Set the window procedure to our func WndProc
   hInstance:=h_Instance;
   hCursor:=LoadCursor(0, IDC_ARROW);
   lpszClassName:='OpenGL';
  end;
 if (RegisterClass(wndClass)=0)
 then  // Attemp to register the window class
  begin
   MessageBox(0, 'Failed to register the window class!', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Change to fullscreen if so desired
 if Fullscreen
 then
  begin
   ZeroMemory(@dmScreenSettings, SizeOf(dmScreenSettings));
    with dmScreenSettings do
     begin              // Set parameters for the screen setting
      dmSize:=SizeOf(dmScreenSettings);
      dmPelsWidth:=Width;                  // Window width
      dmPelsHeight:=Height;                 // Window height
      dmBitsPerPel:=PixelDepth;             // Window color depth
      dmFields:=DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
    end;
   // Try to change screen mode to fullscreen
   if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN)=DISP_CHANGE_FAILED)
   then
    begin
     MessageBox(0, 'Unable to switch to fullscreen!', 'Error', MB_OK or MB_ICONERROR);
     Fullscreen:=false;
    end;
  end;
 // If we are still in fullscreen then
 if (Fullscreen)
 then
  begin
   dwStyle:=WS_POPUP or                // Creates a popup window
            WS_CLIPCHILDREN            // Doesn't draw within child windows
            or WS_CLIPSIBLINGS;        // Doesn't draw within sibling windows
   dwExStyle:=WS_EX_APPWINDOW;         // Top level window
   ShowCursor(False);                    // Turn of the cursor (gets in the way)
  end
 else
  begin
   dwStyle:=WS_OVERLAPPEDWINDOW or     // Creates an overlapping window
            WS_CLIPCHILDREN or         // Doesn't draw within child windows
            WS_CLIPSIBLINGS;           // Doesn't draw within sibling windows
   dwExStyle:=WS_EX_APPWINDOW or       // Top level window
              WS_EX_WINDOWEDGE;        // Border with a raised edge
   ShowCursor(False);                    // Turn of the cursor (gets in the way)
  end;
 // Attempt to create the actual window
 h_Wnd:=CreateWindowEx(dwExStyle,      // Extended window styles
                          'OpenGL',       // Class name
                          WND_TITLE,      // Window title (caption)
                          dwStyle,        // Window styles
                          0, 0,           // Window position
                          Width, Height,  // Size of window
                          0,              // No parent window
                          0,              // No menu
                          h_Instance,     // Instance
                          nil);           // Pass nothing to WM_CREATE
 if h_Wnd=0
 then
  begin
   glKillWnd(Fullscreen);                // Undo all the settings we've changed
   MessageBox(0, 'Unable to create window!', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Try to get a device context
 h_DC:=GetDC(h_Wnd);
 if (h_DC=0)
 then
  begin
   glKillWnd(Fullscreen);
   MessageBox(0, 'Unable to get a device context!', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Settings for the OpenGL window
 with pfd do
  begin
   nSize:=SizeOf(TPIXELFORMATDESCRIPTOR); // Size Of This Pixel Format Descriptor
   nVersion:=1;                    // The version of this data structure
   dwFlags:=PFD_DRAW_TO_WINDOW    // Buffer supports drawing to window
           or PFD_SUPPORT_OPENGL // Buffer supports OpenGL drawing
           or PFD_DOUBLEBUFFER;  // Supports double buffering
    iPixelType:=PFD_TYPE_RGBA;        // RGBA color format
    cColorBits:=PixelDepth;           // OpenGL color depth
    cRedBits:=0;                    // Number of red bitplanes
    cRedShift:=0;                    // Shift count for red bitplanes
    cGreenBits:=0;                    // Number of green bitplanes
    cGreenShift:=0;                    // Shift count for green bitplanes
    cBlueBits:=0;                    // Number of blue bitplanes
    cBlueShift:=0;                    // Shift count for blue bitplanes
    cAlphaBits:=0;                    // Not supported
    cAlphaShift:=0;                    // Not supported
    cAccumBits:=0;                    // No accumulation buffer
    cAccumRedBits:=0;                    // Number of red bits in a-buffer
    cAccumGreenBits:=0;                    // Number of green bits in a-buffer
    cAccumBlueBits:=0;                    // Number of blue bits in a-buffer
    cAccumAlphaBits:=0;                    // Number of alpha bits in a-buffer
    cDepthBits:=16;                   // Specifies the depth of the depth buffer
    cStencilBits:=0;                    // Turn off stencil buffer
    cAuxBuffers:=0;                    // Not supported
    iLayerType:=PFD_MAIN_PLANE;       // Ignored
    bReserved:=0;                    // Number of overlay and underlay planes
    dwLayerMask:=0;                    // Ignored
    dwVisibleMask:=0;                    // Transparent color of underlay plane
    dwDamageMask:=0;                     // Ignored
  end;
 // Attempts to find the pixel format supported by a device context that is the best match to a given pixel format specification.
 PixelFormat:=ChoosePixelFormat(h_DC, @pfd);
 if (PixelFormat=0)
 then
  begin
   glKillWnd(Fullscreen);
   MessageBox(0, 'Unable to find a suitable pixel format', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Sets the specified device context's pixel format to the format specified by the PixelFormat.
 if (not SetPixelFormat(h_DC, PixelFormat, @pfd))
 then
  begin
   glKillWnd(Fullscreen);
   MessageBox(0, 'Unable to set the pixel format', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Create a OpenGL rendering context
 h_RC:=wglCreateContext(h_DC);
 if (h_RC=0)
 then
  begin
   glKillWnd(Fullscreen);
   MessageBox(0, 'Unable to create an OpenGL rendering context', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Makes the specified OpenGL rendering context the calling thread's current rendering context
 if (not wglMakeCurrent(h_DC, h_RC))
 then
  begin
   glKillWnd(Fullscreen);
   MessageBox(0, 'Unable to activate OpenGL rendering context', 'Error', MB_OK or MB_ICONERROR);
   Result:=false;
   Exit;
  end;
 // Initializes the timer used to calculate the FPS
 SetTimer(h_Wnd, FPS_TIMER, FPS_INTERVAL, nil);
 // Settings to ensure that the window is the topmost window
 ShowWindow(h_Wnd, SW_SHOW);
 SetForegroundWindow(h_Wnd);
 SetFocus(h_Wnd);
 // Ensure the OpenGL window is resized properly
 glResizeWnd(Width, Height);
 glInit();
 Result:=true;
end;

// Main message loop for the application
function WinMain(hInstance : HINST; hPrevInstance : HINST;
                 lpCmdLine : PChar; nCmdShow : Integer) : Integer; stdcall;
var
 msg: TMsg;
 finished: Boolean;
 DemoStart, LastTime: DWord;
begin
 finished:=false;
 // Perform application initialization:
 if not glCreateWnd(800, 600, FALSE, 32)
 then
  begin
   Result:=0;
   Exit;
  end;
 DemoStart:=GetTickCount();            // Get Time when demo started
 SetCursorPos(400,300);
 // Main message loop:
 while not finished do
  begin
   if (PeekMessage(msg, 0, 0, 0, PM_REMOVE))
   then // Check if there is a message for this window
    begin
     if (msg.message=WM_QUIT)
     then finished:=true // If WM_QUIT message received then we are done
     else
      begin                               // Else translate and dispatch the message to this window
  	   TranslateMessage(msg);
       DispatchMessage(msg);
      end;
    end
   else
    begin
     Inc(FPSCount);                      // Increment FPS Counter
     FrameTime:=GetTickCount()-ElapsedTime-DemoStart;
     LastTime:=ElapsedTime;
     ElapsedTime:=GetTickCount()-DemoStart;     // Calculate Elapsed Time
     ElapsedTime:=(LastTime+ElapsedTime) div 2; // Average it out for smoother movement
     // use mouse coordinates to calculate heading and tilt and reset mouse.
     if GetForegroundWindow=h_Wnd
     then
      begin
       GetCursorPos(mpos);
       SetCursorPos(400,300);
       Heading:=Heading+(mpos.x-400)/100*MouseSpeed;
       Tilt:=Tilt-(300-mpos.y)/100*MouseSpeed;
       if Tilt>60 then Tilt:=60;
       if Tilt<-60 then Tilt:=-60;
      end;
     glDraw();                           // Draw the scene
     SwapBuffers(h_DC);                  // Display the scene
     if (keys[VK_ESCAPE])
     then finished:=true // If user pressed ESC then set finised TRUE
     else ProcessKeys;                      // Check for any other key Pressed
    end;
  end;
 glKillWnd(FALSE);
 Result:=msg.wParam;
end;

begin
 WinMain(hInstance, hPrevInst, CmdLine, CmdShow);
end.
