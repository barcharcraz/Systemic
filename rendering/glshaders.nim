import exceptions
import logging
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


"""

proc genDefine*(name: string, val: auto): string =
  result = "#define " & name & " " & $val & "\n"

