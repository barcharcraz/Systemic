import exceptions
import logging
const BasicVS* = """
#version 140
struct matrices_t {
  mat4 model;
  mat4 view;
  mat4 proj;
};

uniform matrices_t mvp;
in vec3 pos;
void main() {
  gl_Position = mvp.proj * mvp.view * mvp.model * vec4(pos, 1);
}
"""
const BasicPS* = """
#version 140
uniform vec3 color;
out vec4 outputColor;
void main() {
  outputColor = vec4(color,1);
}
"""
const LightStructs* = """

struct pointLight_t {
    vec4 diffuse;
    vec4 specular;
    vec4 position;
    float cutoff;
    float constant;
    float linear;
    float quadratic;
};
struct directionalLight_t {
    vec4 diffuse;
    vec4 specular;
    vec4 direction;
};
struct spotLight_t {
  vec4 diffuse;
  vec4 specular;
  vec4 direction;
  vec4 position;
  float cutoff;
  float fov;
};
struct material_t {
    vec4 ambiant;
    vec4 diffuse;
    vec4 specular;
    float shine;
};


"""
const ForwardLighting* = """

vec4 phongLight(in material_t mat,
                in vec4 viewDir,
                in vec4 lvec,
                in vec4 norm,
                in vec4 ldiffuse,
                in vec4 lspec)
{
    float cosAngIncidence = dot(lvec, norm);
    clamp(cosAngIncidence, 0,1);
    vec4 rv = (mat.diffuse * cosAngIncidence * ldiffuse);
    if(cosAngIncidence > 0) {
        vec4 refvec = reflect(lvec, norm);
        float phong = dot(refvec, viewDir);
        phong = clamp(phong, 0.0, 1.0);
        phong = pow(max(phong,0.0), mat.shine);
        vec4 spec = mat.specular * phong * lspec;
        spec = clamp(spec, 0.0, 1.0);
        rv += spec;
    }
    rv = clamp(rv, 0.0, 1.0);
    return rv; 
}
vec4 pointLight(in pointLight_t light,
                in vec4 normal,
                in vec4 viewPos,
                in material_t mat)
{
    float distance = distance(viewPos, light.position);
    if(distance > light.cutoff) {
      return vec4(0,0,0,0);
    }
    vec4 lvec = normalize(viewPos - light.position);
    vec4 rv = phongLight(mat, normalize(viewPos), lvec, normalize(normal), light.diffuse, light.specular);
    float linear = light.linear * distance;
    float quad = light.quadratic * pow(distance, 2);
    rv = rv * 1 / (light.constant + linear + quad);
    return rv;
}
vec4 directionalLight(in directionalLight_t light,
                      in vec4 norm,
                      in vec4 viewPos,
                      in material_t mat)
{
    return phongLight(mat, normalize(viewPos), normalize(-light.direction), normalize(norm), light.diffuse, light.specular);
}
vec4 spotLight(in spotLight_t light,
               in vec4 norm,
               in vec4 viewPos,
               in material_t mat)
{
  float distance = distance(viewPos, light.position);
  float angle = acos(dot(normalize(viewPos), light.direction));
  if(angle > (light.fov / 2)) {
    return vec4(0,0,0,0);
  }
  if(distance > light.cutoff) {
    return vec4(0,0,0,0);
  }
  vec4 rv = phongLight(mat, normalize(viewPos), normalize(viewPos- light.position), normalize(norm), light.diffuse, light.specular);
  return rv;
}

"""
const FloatPacking* = """
vec4 pack_float(const in float val) {
  const vec4 bit_shift = vec4(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0, 1.0);
  const vec4 bit_mask = vec4(0.0, 1.0/256.0, 1.0/256.0, 1.0/256.0, 1.0/256.0);
  vec4 res = fract(val * bit_shift)
  res -= res.xxyz * bit_mask;
  resutn res;
}
"""
proc genDefine*(name: string, val: auto): string =
  result = "#define " & name & " " & $val & "\n"

