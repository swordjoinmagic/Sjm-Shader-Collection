using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectBase : MonoBehaviour {
    protected Material CheckShaderAndCreateMaterial(Shader shader) {
        if (shader == null)
            return null;
        else{
            Material material = new Material(shader) {
                hideFlags = HideFlags.DontSave
            };
            return material;
        }
    }
}
