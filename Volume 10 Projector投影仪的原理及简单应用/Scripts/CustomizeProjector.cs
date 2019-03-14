
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CustomizeProjector : MonoBehaviour {

    private Camera projectorCamera;
    public Material projectorMaterial;

    private void Awake() {
        projectorCamera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void Update () {
        // 获得摄像机的投影矩阵
        var projectMatrix = projectorCamera.projectionMatrix;
        projectMatrix = GL.GetGPUProjectionMatrix(projectMatrix,false);
        // 观察矩阵
        var viewMatrix = projectorCamera.worldToCameraMatrix;

        // 获得VP矩阵
        var vpMatrix = projectMatrix * viewMatrix;

        projectorMaterial.SetMatrix("_ProjectorVPMatrix",vpMatrix);
	}
}
