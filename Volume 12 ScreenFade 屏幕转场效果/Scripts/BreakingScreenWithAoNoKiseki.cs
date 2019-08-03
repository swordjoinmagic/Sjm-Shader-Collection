using UnityEngine;

/// <summary>
/// 仿碧轨碎屏效果
/// 
/// 思路：
///     1. 
/// </summary>
public class BreakingScreenWithAoNoKiseki : MonoBehaviour{

    // 观察这个碎屏特效的摄像机
    private Camera effectCamera;

    // 用于破碎的平面的宽度
    private float width;
    // 用于破碎的平面的高度
    private float height;

    // 将Width和Height分成N份
    public int rowTriangleSize = 2;
    public int colTriangleSize = 2;

    // 碎屏的模型
    private GameObject screenObject;
    private MeshFilter meshFilter;
    private MeshRenderer meshRenderer;

    // 碎屏所使用的Shader（其实就是一张简单的纹理贴图Shader）
    public Shader breakingScreenShader;
    private Material breakingScreenMaterial;

    private Material BreakingScreenMaterial {
        get {
            if (breakingScreenMaterial == null) {
                if (breakingScreenShader != null)
                    breakingScreenMaterial = new Material(breakingScreenShader);
                else
                    return null;
            }
            return breakingScreenMaterial;
        }
    }

    // mesh顶点序列
    private Vector3[] vertices;
    // uv序列
    private Vector2[] uv;
    // mesh顶点索引序列
    private int[] triangles;

    private void Start() {
        effectCamera = transform.parent.GetComponent<Camera>();
        height = effectCamera.orthographicSize * 2;
        width = effectCamera.aspect * height;

        screenObject = new GameObject("Screen Object");
        screenObject.layer = 13;
        screenObject.transform.SetParent(effectCamera.transform,false);
        screenObject.transform.position = new Vector3(screenObject.transform.position.x,screenObject.transform.position.y,effectCamera.nearClipPlane+1);
        meshFilter = screenObject.AddComponent<MeshFilter>();
        meshRenderer = screenObject.AddComponent<MeshRenderer>();
        screenObject.transform.localScale = new Vector3(width,height,1);
        meshRenderer.material = BreakingScreenMaterial;

        //GenerateMesh();
        Mesh mesh = meshFilter.mesh;
        uv = new Vector2[6];
        uv[0] = new Vector2(0, 0);
        uv[1] = new Vector2(0, 1);
        uv[2] = new Vector2(1, 0);
        uv[3] = new Vector2(0, 1);
        uv[4] = new Vector2(1, 1);
        uv[5] = new Vector2(1, 0);

        vertices = new Vector3[6];
        vertices[0] = new Vector3(0, 0, 0);
        vertices[1] = new Vector3(0, 1, 0);
        vertices[2] = new Vector3(1, 0, 0);
        vertices[3] = new Vector3(0, 1, 0);
        vertices[4] = new Vector3(1, 1, 0);
        vertices[5] = new Vector3(1, 0, 0);


        triangles = new int[6];
        triangles[0] = 0;
        triangles[1] = 1;
        triangles[2] = 2;
        triangles[3] = 3;
        triangles[4] = 4;
        triangles[5] = 5;


        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uv;

        mesh.RecalculateNormals();      // 重新计算法线
    }

    // 生成碎屏Mesh（由一块块碎片拼起来的四边形（此四边形覆盖屏幕））
    // 此Mesh的X、Y坐标限定在[0,1]范围内
    private void GenerateMesh() {

        // 初始化
        vertices = new Vector3[rowTriangleSize*colTriangleSize*6];
        uv = new Vector2[vertices.Length];
        triangles = new int[vertices.Length];


        int index = 0;
        float rowStep = (float)1 / rowTriangleSize;
        float colStep = (float)1 / colTriangleSize;
        for (int i=0;i< rowTriangleSize-1; i++) {
            for (int j=0;j<colTriangleSize-1;j++) {

                // 生成原点位于左下角的，坐标在(i,j)的四边形图元
                // 生成一个四边形图元需要两个三角形图元，即6个顶点

                // 顶点1
                vertices[index] = new Vector3(i*rowStep,j*colStep,0);
                triangles[index] = index;
                uv[index] = new Vector2(vertices[index].x,vertices[index].y);
                index++;

                // 顶点2
                vertices[index] = vertices[index - 1] + new Vector3(0,colStep,0);
                triangles[index] = index;
                uv[index] = new Vector2(vertices[index].x, vertices[index].y);
                index++;

                // 顶点3
                vertices[index] = vertices[index - 2] + new Vector3(rowStep, 0, 0);
                triangles[index] = index;
                uv[index] = new Vector2(vertices[index].x, vertices[index].y);
                index++;

                // 顶点4
                vertices[index] = vertices[index - 2];
                triangles[index] = index;
                uv[index] = new Vector2(vertices[index].x, vertices[index].y);
                index++;

                // 顶点5
                vertices[index] = vertices[index - 1] + new Vector3(rowStep, 0, 0);
                triangles[index] = index;
                uv[index] = new Vector2(vertices[index].x, vertices[index].y);
                index++;

                // 顶点6
                vertices[index] = vertices[index - 1] + new Vector3(0, -colStep, 0);
                triangles[index] = index;
                uv[index] = new Vector2(vertices[index].x, vertices[index].y);
                index++;
            }
        }

        meshFilter.mesh.vertices = vertices;
        meshFilter.mesh.triangles = triangles;
        meshFilter.mesh.uv = uv;
    }

    

    private void Update() {
        
    }
}

