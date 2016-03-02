import com.dscleaver.sbt.SbtQuickFix._

cancelable in Global := true

QuickFixKeys.vimPluginBaseDirectory := file(sys.props("user.home") + "/.config/nvim/bundle")
//
//QuickFixKeys.vimEnableServer := false
//
QuickFixKeys.vimExecutable := "nvim"
