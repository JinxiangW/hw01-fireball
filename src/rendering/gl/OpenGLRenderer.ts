import { mat4, vec4 } from "gl-matrix";
import Drawable from "./Drawable";
import Camera from "../../Camera";
import { gl } from "../../globals";
import ShaderProgram from "./ShaderProgram";
import { Console } from "console";

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {}

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(
    camera: Camera,
    prog: ShaderProgram,
    drawables: Array<Drawable>,
    inputColor: Array<number> = [1, 0, 0, 1],
    mouseInput: Array<number> = [0, 0],
    octaves: number = 2,
    speed: number = 1.0
  ) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = vec4.fromValues(
      inputColor[0],
      inputColor[1],
      inputColor[2],
      inputColor[3]
    );

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);

    gl.uniform1f(
      gl.getUniformLocation(prog.prog, "u_Time"),
      performance.now() / 1000
    );
    gl.uniform3fv(
      gl.getUniformLocation(prog.prog, "u_Camera"),
      camera.controls.eye
    );

    // screen resolution
    gl.uniform2f(
      gl.getUniformLocation(prog.prog, "u_Resolution"),
      this.canvas.width,
      this.canvas.height
    );

    // get mouse position
    gl.uniform2f(
      gl.getUniformLocation(prog.prog, "u_Mouse"),
      mouseInput[0],
      mouseInput[1]
    );

    // initialize inverse of vp matrix
    let invVP = mat4.create();
    mat4.invert(invVP, viewProj);
    gl.uniformMatrix4fv(
      gl.getUniformLocation(prog.prog, "u_InvVP"),
      false,
      invVP
    );

    // set octaves
    gl.uniform1i(gl.getUniformLocation(prog.prog, "u_Octaves"), octaves);
    for (let drawable of drawables) {
      prog.draw(drawable);
    }

    // set speed
    gl.uniform1f(gl.getUniformLocation(prog.prog, "u_Speed"), speed);
  }
}

export default OpenGLRenderer;
