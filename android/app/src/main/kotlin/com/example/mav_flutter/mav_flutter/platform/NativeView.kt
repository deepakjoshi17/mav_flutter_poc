package com.example.mav_flutter.mav_flutter.platform
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.widget.EditText
import android.widget.FrameLayout
import androidx.annotation.RequiresApi
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.RecyclerView
import com.amazonaws.ivs.broadcast.Bluetooth
import com.example.mav_flutter.mav_flutter.R
import com.example.mav_flutter.mav_flutter.stage.StageLayoutManager
import com.example.mav_flutter.mav_flutter.vm.NativeViewModel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.platform.PlatformView

@RequiresApi(Build.VERSION_CODES.P)
internal class NativeView(context: FlutterFragmentActivity, id: Int, creationParams: Map<String?, Any?>?) : FrameLayout(context), PlatformView {
    private lateinit var textView: EditText
    private lateinit var viewModel: NativeViewModel
    private var recyclerView: RecyclerView
    init {
        // Get ViewModel from parent Activity
        val activity = context as? androidx.activity.ComponentActivity
            ?: throw IllegalStateException("Context must be a ComponentActivity")
        viewModel = ViewModelProvider(activity)[NativeViewModel::class.java]
        
        Bluetooth.startBluetoothSco(context)
        val customView = LayoutInflater.from(context).inflate(R.layout.activity_maveric_home, this, true)
        recyclerView = customView.findViewById(R.id.main_recycler_view)

        recyclerView.layoutManager = StageLayoutManager(context)
        recyclerView.adapter = viewModel.participantAdapter
        
        viewModel.setPublishEnabled(viewModel.canPublish)
    }

    override fun getView(): View {
        return this
    }

    override fun dispose() {
        Bluetooth.stopBluetoothSco(context)
    }
}