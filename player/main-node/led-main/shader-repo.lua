return {
    multisample = resource.create_shader[[
        uniform sampler2D Texture;
        varying vec2 TexCoord;
        uniform vec4 Color;
        uniform float x, y, s;
        void main() {
            vec2 texcoord = TexCoord * vec2(s, s) + vec2(x, y);
            vec4 c1 = texture2D(Texture, texcoord);
            vec4 c2 = texture2D(Texture, texcoord + vec2(0.0002, 0.0002));
            gl_FragColor = (c2+c1)*0.5 * Color;
        }
    ]],
    simple = resource.create_shader[[
        uniform sampler2D Texture;
        varying vec2 TexCoord;
        uniform vec4 Color;
        uniform float x, y, s;
        void main() {
            gl_FragColor = texture2D(Texture, TexCoord * vec2(s, s) + vec2(x, y)) * Color;
        }
    ]],
    progress = resource.create_shader[[
        uniform sampler2D Texture;
        varying vec2 TexCoord;
        uniform float progress_angle;
        float interp(float x) {
            return 2.0 * x * x * x - 3.0 * x * x + 1.0;
        }
        void main() {
            vec2 pos = TexCoord;
            float angle = atan(pos.x - 0.5, pos.y - 0.5);
            float dist = clamp(distance(pos, vec2(0.5, 0.5)), 0.0, 0.5) * 2.0;
            float alpha = interp(pow(dist, 8.0));
            if (angle > progress_angle) {
                gl_FragColor = vec4(1.0, 1.0, 1.0, alpha);
            } else {
                gl_FragColor = vec4(0.5, 0.5, 0.5, alpha);
            }
        }
    ]]
}
