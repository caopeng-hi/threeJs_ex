

void main(){
    gl_Position = uProjection * uModelView * vec4(position, 1.0);
}